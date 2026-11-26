import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/chat_badge.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';

/// Ruang percakapan. Pemilik bisa menghapus pesan; penyewa tidak.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    this.initialRoom,
    this.initialTitle,
    this.isOwner = false,
  });

  final String roomId;

  /// Ringkasan ruang opsional supaya judul langsung benar sebelum fetch selesai.
  final ChatRoom? initialRoom;
  final String? initialTitle;
  final bool isOwner;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _lifecycleActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vercel serverless tidak bisa menyimpan soket WebSocket yang terbuka,
    // jadi pesan baru diambil dengan polling tiga detik selama layar terlihat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openRoom(widget.roomId);
      _startPolling();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifecycleActive = state == AppLifecycleState.resumed;
    if (_lifecycleActive) {
      _startPolling();
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _startPolling() {
    if (!_lifecycleActive || !mounted) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted || !_lifecycleActive) return;
      context.read<ChatProvider>().refreshMessages(widget.roomId);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _title {
    final title = widget.initialTitle ?? widget.initialRoom?.displayName;
    if (title != null && title.trim().isNotEmpty) return title;
    final room = context.read<ChatProvider>().rooms;
    for (final item in room) {
      if (item.id == widget.roomId) return item.displayName;
    }
    return 'Percakapan';
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<ChatProvider>();
    final ok = await provider.sendMessage(widget.roomId, content);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      _scrollToBottom();
      // Polling berikutnya mengembalikan pesan ini dari server, jadi tidak
      // perlu menunggu sukses snackbar yang mengganggu percakapan.
    } else if (provider.actionError != null) {
      showError(context, provider.actionError!);
    }
  }

  Future<void> _confirmDelete(String messageId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus pesan?',
      message: 'Pesan ini akan dihapus untuk semua orang dalam percakapan.',
      confirmLabel: 'Hapus',
    );
    if (!confirmed || !mounted) return;

    final provider = context.read<ChatProvider>();
    final ok = await provider.deleteMessage(widget.roomId, messageId);
    if (!mounted) return;
    if (ok) {
      showSuccess(context, 'Pesan dihapus');
    } else if (provider.actionError != null) {
      showError(context, provider.actionError!);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select<AuthProvider, String?>(
      (auth) => auth.user?.id,
    );
    final provider = context.watch<ChatProvider>();
    final messages = provider.messagesFor(widget.roomId);
    final isDirectRoom = widget.initialRoom?.isDirect ??
        provider.rooms.any(
          (room) => room.id == widget.roomId && room.isDirect,
        );

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Column(
        children: [
          if (isDirectRoom) _buildSafetyBanner(),
          Expanded(child: _buildMessages(provider, messages, currentUserId)),
          _buildComposer(provider),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.warningText.withValues(alpha: 0.10),
      child: Text(
        'Demi keamanan transaksi dan garansi pemesanan, lakukan seluruh pembayaran melalui sistem aplikasi.',
        style: AppFonts.label(
          11,
          color: AppColors.warningText,
        ),
      ),
    );
  }

  Widget _buildMessages(
    ChatProvider provider,
    List<ChatMessage> messages,
    String? currentUserId,
  ) {
    if (provider.loadingMessages && messages.isEmpty) {
      return const LoadingView(message: 'Memuat percakapan...');
    }
    if (provider.messagesError != null && messages.isEmpty) {
      return ErrorState(
        message: provider.messagesError!,
        onRetry: () => provider.openRoom(widget.roomId),
      );
    }
    if (messages.isEmpty) {
      return const EmptyState(
        title: 'Belum ada pesan',
        description: 'Tulis pesan pertama untuk mulai berbicara.',
        icon: Icons.chat_bubble_outline,
      );
    }

    // Pesan terakhir ditampilkan di bawah; penambahan pesan baru perlu scroll.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length,
      itemBuilder: (context, index) =>
          _buildItem(messages[index], currentUserId),
    );
  }

  Widget _buildItem(ChatMessage message, String? currentUserId) {
    if (message.isSystemMessage) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: AppFonts.label(
              11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final mine = message.isFrom(currentUserId);
    final showBadge = ChatBadge.shouldShow(message.roomBadge);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.76,
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showBadge || !mine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!mine) ...[
                          Text(
                            message.senderName,
                            style: AppFonts.label(
                              11,
                              weight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        if (showBadge)
                          ChatBadge(label: message.roomBadge!, compact: true),
                      ],
                    ),
                  ),
                GestureDetector(
                  onLongPress: widget.isOwner
                      ? () => _confirmDelete(message.id)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine ? AppColors.buttonBg : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(mine ? 16 : 4),
                        bottomRight: Radius.circular(mine ? 4 : 16),
                      ),
                      border: mine
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            message.content,
                            style: AppFonts.label(
                              13.5,
                              color: mine
                                  ? AppColors.onButton
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.isOwner) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _confirmDelete(message.id),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: mine
                                  ? AppColors.onButton
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    message.timeLabel,
                    style: AppFonts.label(10, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(ChatProvider provider) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !provider.sending,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: provider.sending ? null : _send,
              tooltip: 'Kirim pesan',
              icon: provider.sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

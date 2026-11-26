import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../screens/shared/chat_room_screen.dart';
import '../../widgets/feedback.dart';
import '../../widgets/state_views.dart';

/// Daftar percakapan, dibagi menjadi chat pribadi dan grup kos.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
    this.propertyId,
    this.isOwner = false,
    this.embedded = false,
  });

  /// Bila diisi dari halaman properti, tombol "Chat pemilik" langsung
  /// membuka/membuat ruang untuk properti ini.
  final String? propertyId;
  final bool isOwner;
  final bool embedded;

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  static const _pollInterval = Duration(seconds: 3);

  Timer? _pollTimer;
  bool _lifecycleActive = true;
  bool _startingDirect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vercel serverless tidak dapat menjaga WebSocket tetap terbuka, jadi
    // jumlah pesan belum dibaca diambil tiap tiga detik selama layar terlihat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadRooms();
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
      context.read<ChatProvider>().refreshRooms();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openRoom(ChatRoom room) async {
    // Dari GoRouter, roomId dikirim lewat extra agar tidak perlu provider
    // global; fallback memakai navigator biasa bila rute chat belum ada.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          roomId: room.id,
          initialRoom: room,
          isOwner: widget.isOwner ||
              context.read<AuthProvider>().user?.isOwner == true,
        ),
      ),
    );
    if (mounted) {
      context.read<ChatProvider>().refreshRooms();
    }
  }

  Future<void> _startDirect() async {
    final propertyId = widget.propertyId;
    if (propertyId == null || propertyId.isEmpty || _startingDirect) return;

    setState(() => _startingDirect = true);
    final room = await context.read<ChatProvider>().startDirect(propertyId);
    if (!mounted) return;
    setState(() => _startingDirect = false);

    if (room == null) {
      final error = context.read<ChatProvider>().actionError;
      showError(context, error ?? 'Gagal membuka percakapan');
      return;
    }
    await _openRoom(room);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(title: const Text('Pesan')),
      floatingActionButton: widget.propertyId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _startingDirect ? null : _startDirect,
              icon: _startingDirect
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_outlined),
              label: const Text('Mulai chat'),
            ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Chat Pribadi'),
                Tab(text: 'Grup Kos'),
              ],
            ),
            Expanded(
              child: _buildBody(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    if (provider.loadingRooms && provider.rooms.isEmpty) {
      return const LoadingView(message: 'Memuat percakapan...');
    }
    if (provider.roomsError != null) {
      return ErrorState(
        message: provider.roomsError!,
        onRetry: provider.loadRooms,
      );
    }

    return TabBarView(
      children: [
        _buildList(provider.rooms.where((room) => room.isDirect).toList()),
        _buildList(provider.rooms.where((room) => room.isGroup).toList()),
      ],
    );
  }

  Widget _buildList(List<ChatRoom> rooms) {
    if (rooms.isEmpty) {
      return const EmptyState(
        title: 'Belum ada percakapan',
        description: 'Percakapan dengan pemilik atau penghuni kos tampil di sini.',
        icon: Icons.forum_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ChatProvider>().loadRooms(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: rooms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final room = rooms[index];
          return Card(
            child: ListTile(
              onTap: () => _openRoom(room),
              title: Text(
                room.propertyName,
                style: AppFonts.label(14, weight: FontWeight.w700),
              ),
              subtitle: Text(
                room.lastMessage ?? 'Belum ada pesan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.label(12, color: AppColors.textSecondary),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    room.lastMessageTime,
                    style: AppFonts.label(10, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  if (room.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.buttonBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${room.unreadCount}',
                        style: AppFonts.label(
                          10,
                          weight: FontWeight.w700,
                          color: AppColors.onButton,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

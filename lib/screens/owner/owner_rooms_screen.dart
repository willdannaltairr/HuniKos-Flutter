import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/room_card.dart';
import '../../widgets/state_views.dart';

/// Daftar kamar satu properti dengan aksi tambah, ubah, dan hapus.
class OwnerRoomsScreen extends StatefulWidget {
  const OwnerRoomsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<OwnerRoomsScreen> createState() => _OwnerRoomsScreenState();
}

class _OwnerRoomsScreenState extends State<OwnerRoomsScreen> {
  @override
  void initState() {
    super.initState();
    // Daftar dibersihkan sebelum memuat agar tidak menampilkan sisa properti lain.
    final provider = context.read<OwnerProvider>();
    provider.clearRooms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadRooms(widget.propertyId);
    });
  }

  Future<void> _delete(String roomId, String number) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus kamar?',
      message: 'Kamar $number akan dihapus permanen.',
      confirmLabel: 'Ya, hapus',
    );
    if (!confirmed || !mounted) return;

    final error = await context
        .read<OwnerProvider>()
        .deleteRoom(roomId, widget.propertyId);
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Kamar dihapus');
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kamar properti')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/owner/properties/${widget.propertyId}/rooms/new',
        ),
        icon: const Icon(Icons.add),
        label: const Text('Kamar'),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(OwnerProvider provider) {
    if (provider.loadingRooms && provider.rooms.isEmpty) {
      return const LoadingView();
    }
    if (provider.roomsError != null) {
      return ErrorState(
        message: provider.roomsError!,
        onRetry: () => provider.loadRooms(widget.propertyId),
      );
    }
    if (provider.rooms.isEmpty) {
      return const EmptyState(
        title: 'Belum ada kamar',
        description: 'Tambahkan kamar pertama untuk properti ini.',
        icon: Icons.meeting_room_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadRooms(widget.propertyId),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: provider.rooms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final room = provider.rooms[index];
          return RoomCard(
            room: room,
            onTap: () => context.push(
              '/owner/properties/${widget.propertyId}/rooms/${room.id}/edit',
              extra: room,
            ),
            trailing: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push(
                    '/owner/properties/${widget.propertyId}/rooms/${room.id}/edit',
                    extra: room,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Ubah'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _delete(room.id, room.roomNumber),
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    foregroundColor: AppColors.dangerText,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

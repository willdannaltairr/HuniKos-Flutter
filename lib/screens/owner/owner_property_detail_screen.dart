import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/owner_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/image_picker_field.dart';
import '../../widgets/network_image_view.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_chip.dart';

/// Detail properti milik pemilik: info, galeri foto, dan pintu masuk ke
/// pengelolaan kamar.
class OwnerPropertyDetailScreen extends StatefulWidget {
  const OwnerPropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  State<OwnerPropertyDetailScreen> createState() =>
      _OwnerPropertyDetailScreenState();
}

class _OwnerPropertyDetailScreenState
    extends State<OwnerPropertyDetailScreen> {
  late Future<PropertyDetail> _future;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PropertyDetail> _load() {
    return context.read<CatalogProvider>().propertyDetail(widget.propertyId);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _upload(List<XFile> files) async {
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    final error = await context.read<OwnerProvider>().uploadImages(
          widget.propertyId,
          files,
        );
    if (!mounted) return;
    setState(() => _uploading = false);
    if (error == null) {
      showSuccess(context, 'Foto berhasil diunggah');
      _reload();
    } else {
      showError(context, error);
    }
  }

  Future<void> _deleteImage(String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Hapus foto?',
      message: 'Foto ini akan dihapus dari properti.',
      confirmLabel: 'Ya, hapus',
    );
    if (!confirmed || !mounted) return;

    final error = await context.read<OwnerProvider>().deleteImage(id);
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Foto dihapus');
      _reload();
    } else {
      showError(context, error);
    }
  }

  Future<void> _setCover(String id) async {
    final error = await context.read<OwnerProvider>().setCover(id);
    if (!mounted) return;
    if (error == null) {
      showSuccess(context, 'Foto dijadikan cover');
      _reload();
    } else {
      showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail properti')),
      body: FutureBuilder<PropertyDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return ErrorState(
              message: error is ApiException ? error.message : 'Gagal memuat properti',
              onRetry: _reload,
            );
          }

          final property = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      property.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusChip(
                    status: property.verificationStatus,
                    label: _verificationLabel(property.verificationStatus),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${property.address}, ${property.city} • Kos ${property.typeLabel}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              if (property.rejectionNote != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Catatan penolakan admin: ${property.rejectionNote}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.dangerText),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          context.push('/owner/properties/${property.id}/rooms'),
                      icon: const Icon(Icons.meeting_room_outlined, size: 18),
                      label: Text('Kamar (${property.rooms.length})'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/owner/properties/${property.id}/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Ubah'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Galeri foto',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_uploading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Maksimal 5 foto per unggahan, 2 MB per foto.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ImagePickerField(
                label: 'Tambah foto',
                multiple: true,
                maxFiles: 5,
                enabled: !_uploading,
                onPicked: _upload,
              ),
              const SizedBox(height: 12),
              if (property.images.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada foto. Foto pertama otomatis menjadi cover.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: property.images.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final image = property.images[index];
                    return _ImageTile(
                      image: image,
                      onDelete: () => _deleteImage(image.id),
                      onCover: () => _setCover(image.id),
                    );
                  },
                ),
              const SizedBox(height: 20),
              const Text(
                'Kamar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (property.rooms.isEmpty)
                const Text(
                  'Belum ada kamar. Tambahkan dari menu Kamar.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                )
              else
                ...property.rooms.map(
                  (room) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Kamar ${room.roomNumber}'),
                      subtitle: Text(
                        '${room.roomType} • ${room.status}',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => context.push(
                        '/owner/properties/${property.id}/rooms',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _verificationLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu verifikasi';
    }
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.onDelete,
    required this.onCover,
  });

  final PropertyImage image;
  final VoidCallback onDelete;
  final VoidCallback onCover;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          NetworkImageView(url: image.imageUrl, borderRadius: 0),
          if (image.isCover)
            const Positioned(
              left: 6,
              top: 6,
              child: StatusChip(
                compact: true,
                status: 'approved',
                label: 'Cover',
              ),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: Row(
              children: [
                if (!image.isCover)
                  _CircleAction(
                    icon: Icons.star_outline,
                    tooltip: 'Jadikan cover',
                    onTap: onCover,
                  ),
                _CircleAction(
                  icon: Icons.delete_outline,
                  tooltip: 'Hapus foto',
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../models/property.dart';
import '../../widgets/network_image_view.dart';

/// Foto kamar: gabungan foto yang sudah tersimpan dan pilihan baru.
///
/// Setiap kamar wajib punya minimal satu foto, jadi komponen ini juga
/// menampilkan pesan kesalahan di luar kotak bila masih kosong.
class RoomPhotoField extends StatefulWidget {
  const RoomPhotoField({
    super.key,
    required this.existing,
    required this.showError,
    this.enabled = true,
    this.onDeleteExisting,
  });

  /// Foto yang sudah ada di server untuk kamar ini.
  final List<PropertyImage> existing;

  /// Bila true dan belum ada foto sama sekali, tampilkan pesan wajib.
  final bool showError;

  final bool enabled;

  /// Menghapus foto lama di server.
  final ValueChanged<String>? onDeleteExisting;

  @override
  State<RoomPhotoField> createState() => RoomPhotoFieldState();
}

class RoomPhotoFieldState extends State<RoomPhotoField> {
  static const _maxPhotos = 5;

  final List<XFile> _files = [];
  final Map<String, Uint8List> _previews = {};
  String? _pickError;

  /// Pilihan baru yang belum diunggah; dibaca form saat menyimpan.
  List<XFile> get files => List.unmodifiable(_files);

  bool get hasAnyPhoto => widget.existing.isNotEmpty || _files.isNotEmpty;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await picker.pickMultiImage(imageQuality: 85);
      } else {
        final single = await picker.pickImage(source: source, imageQuality: 85);
        picked = single == null ? const [] : [single];
      }
      if (picked.isEmpty) return;
      await _accept(picked);
    } catch (error) {
      setState(() => _pickError = 'Gagal membuka gambar: $error');
    }
  }

  Future<void> _accept(List<XFile> picked) async {
    final accepted = <XFile>[];
    String? error;

    for (final file in picked) {
      if (!_isAllowed(file)) {
        error = 'Hanya gambar jpg, png, atau webp yang boleh dipilih';
        continue;
      }
      if (await file.length() > AppConfig.maxImageBytes) {
        error = 'Ukuran gambar maksimal 2 MB';
        continue;
      }
      final total = widget.existing.length + _files.length + accepted.length;
      if (total >= _maxPhotos) {
        error = 'Maksimal $_maxPhotos foto per kamar';
        break;
      }
      accepted.add(file);
    }

    for (final file in accepted) {
      _files.add(file);
      _previews[file.path] = await file.readAsBytes();
    }
    setState(() => _pickError = error);
  }

  bool _isAllowed(XFile file) {
    final type = file.mimeType;
    if (type != null) return AppConfig.allowedImageTypes.contains(type);
    final name = file.name.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }

  void _remove(XFile file) {
    setState(() {
      _files.remove(file);
      _previews.remove(file.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.showError && !hasAnyPhoto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Foto kamar',
                style: AppFonts.label(13, weight: FontWeight.w700),
              ),
            ),
            Text(
              '${widget.existing.length + _files.length}/$_maxPhotos',
              style: AppFonts.label(11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Wajib minimal satu foto. Foto pertama menjadi sampul kamar.',
          style: AppFonts.label(11.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: empty ? AppColors.danger : AppColors.border,
              width: empty ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.existing.isNotEmpty || _files.isNotEmpty)
                SizedBox(
                  height: 86,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final image in widget.existing)
                        _Tile(
                          onRemove: widget.onDeleteExisting == null
                              ? null
                              : () => widget.onDeleteExisting!(image.id),
                          child: NetworkImageView(
                            url: image.imageUrl,
                            width: 86,
                            height: 86,
                            borderRadius: 10,
                          ),
                        ),
                      for (final file in _files)
                        _Tile(
                          onRemove: () => _remove(file),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _previews[file.path]!,
                              width: 86,
                              height: 86,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (widget.existing.isNotEmpty || _files.isNotEmpty)
                const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.enabled ? () => _pick(ImageSource.gallery) : null,
                    icon: const Icon(Icons.photo_library_outlined, size: 17),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: widget.enabled ? () => _pick(ImageSource.camera) : null,
                    icon: const Icon(Icons.photo_camera_outlined, size: 17),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (empty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 13, color: AppColors.dangerText),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Setiap kamar wajib punya minimal satu foto',
                    style: AppFonts.label(11.5, color: AppColors.dangerText),
                  ),
                ),
              ],
            ),
          ),
        if (_pickError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
            child: Text(
              _pickError!,
              style: AppFonts.label(11.5, color: AppColors.dangerText),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.child, this.onRemove});

  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (onRemove != null)
            Positioned(
              top: -6,
              right: 2,
              child: IconButton.filled(
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  minimumSize: const Size(24, 24),
                  padding: EdgeInsets.zero,
                ),
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

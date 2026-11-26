import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config.dart';
import '../core/theme.dart';

/// Memilih gambar dari galeri/kamera dengan pratinjau dan validasi tipe serta
/// ukuran di sisi client. Server tetap memeriksa ulang.
class ImagePickerField extends StatefulWidget {
  const ImagePickerField({
    super.key,
    required this.onPicked,
    this.label = 'Pilih gambar',
    this.multiple = false,
    this.maxFiles = 1,
    this.enabled = true,
  });

  final ValueChanged<List<XFile>> onPicked;
  final String label;
  final bool multiple;
  final int maxFiles;
  final bool enabled;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final List<XFile> _files = [];
  final Map<String, Uint8List> _previews = {};
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final List<XFile> picked;
      if (widget.multiple) {
        picked = await picker.pickMultiImage(imageQuality: 85);
      } else {
        final single = await picker.pickImage(source: source, imageQuality: 85);
        picked = single == null ? const [] : [single];
      }

      if (picked.isEmpty) return;
      await _accept(picked);
    } catch (error) {
      setState(() => _error = 'Gagal membuka gambar: $error');
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
      final length = await file.length();
      if (length > AppConfig.maxImageBytes) {
        error = 'Ukuran gambar maksimal 2 MB';
        continue;
      }
      if (_files.length + accepted.length >= widget.maxFiles) {
        error = 'Maksimal ${widget.maxFiles} gambar';
        break;
      }
      accepted.add(file);
    }

    for (final file in accepted) {
      _files.add(file);
      _previews[file.path] = await file.readAsBytes();
    }

    setState(() => _error = error);
    if (accepted.isNotEmpty) widget.onPicked(List.unmodifiable(_files));
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
    widget.onPicked(List.unmodifiable(_files));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.enabled ? () => _pick(ImageSource.gallery) : null,
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(widget.label),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
            ),
            if (!widget.multiple) ...[
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: widget.enabled ? () => _pick(ImageSource.camera) : null,
                icon: const Icon(Icons.photo_camera_outlined),
                tooltip: 'Ambil dari kamera',
              ),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: TextStyle(color: AppColors.dangerText, fontSize: 12),
          ),
        ],
        if (_previews.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _previews.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final entry = _previews.entries.elementAt(index);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        entry.value,
                        width: 82,
                        height: 82,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton.filled(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          minimumSize: const Size(24, 24),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          final file = _files.firstWhere(
                            (item) => item.path == entry.key,
                            orElse: () => _files.first,
                          );
                          _remove(file);
                        },
                        icon: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/theme.dart';
import 'image_picker_field.dart';

/// Lembar bawah untuk memilih bukti transfer. Dipakai saat penyewa membayar
/// lewat transfer bank, bukan Midtrans, jadi tidak perlu layar penuh.
class ProofUploadSheet extends StatefulWidget {
  const ProofUploadSheet({super.key});

  /// Mengembalikan berkas yang dipilih, atau null bila pengguna menutup sheet.
  static Future<XFile?> show(BuildContext context) {
    return showModalBottomSheet<XFile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const ProofUploadSheet(),
    );
  }

  @override
  State<ProofUploadSheet> createState() => _ProofUploadSheetState();
}

class _ProofUploadSheetState extends State<ProofUploadSheet> {
  XFile? _file;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Unggah bukti transfer',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pemilik akan memeriksa bukti ini. Maksimal 2 MB, '
            'format jpg, png, atau webp.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ImagePickerField(
            label: 'Pilih gambar bukti',
            onPicked: (files) =>
                setState(() => _file = files.isEmpty ? null : files.first),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _file == null ? null : () => Navigator.of(context).pop(_file),
            child: const Text('Kirim bukti'),
          ),
        ],
      ),
    );
  }
}

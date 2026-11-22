import 'package:flutter/material.dart';

/// Konfirmasi untuk semua aksi hapus dan aksi yang mengubah data penting.
/// Tombol destruktif memakai warna bahaya agar tidak tertekan tanpa sadar.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya, lanjutkan',
  String cancelLabel = 'Batal',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  minimumSize: const Size(0, 40),
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Dialog keputusan (setujui/tolak) dengan catatan opsional atau wajib.
/// Mengembalikan `confirmed: false` bila pengguna menutup dialog.
Future<({bool confirmed, String note})> showDecisionDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool requireNote = false,
  bool destructive = false,
}) async {
  final controller = TextEditingController();
  String? noteError;

  final result = await showDialog<({bool confirmed, String note})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 300,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: requireNote ? 'Catatan (wajib)' : 'Catatan (opsional)',
                counterText: '',
                errorText: noteError,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop((confirmed: false, note: '')),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    minimumSize: const Size(0, 40),
                  )
                : null,
            onPressed: () {
              final note = controller.text.trim();
              if (requireNote && note.length < 3) {
                setState(() => noteError = 'Catatan minimal 3 karakter');
                return;
              }
              Navigator.of(context).pop((confirmed: true, note: note));
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );

  return result ?? (confirmed: false, note: '');
}

/// SnackBar seragam supaya pesan sukses dan gagal selalu terlihat sama.
void showSuccess(BuildContext context, String message) {
  _show(context, message, const Color(0xFF15803D));
}

void showError(BuildContext context, String message) {
  _show(context, message, const Color(0xFFB91C1C));
}

void _show(BuildContext context, String message, Color color) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
}

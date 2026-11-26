import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunikos/core/theme.dart';
import 'package:hunikos/screens/auth/auth_field.dart';

// Uji perilaku kolom auth: pesan kesalahan harus muncul di luar kotak, dan
// garis kotaknya berubah merah. Tampilan tidak bisa diperiksa lewat screenshot
// karena Flutter web menggambar ke canvas.
void main() {
  testWidgets('pesan kesalahan tampil di luar kotak dan garisnya memerah', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(ThemeMode.light),
        home: Scaffold(
          body: Form(
            child: AuthField(
              controller: controller,
              label: 'Nomor telepon',
              icon: Icons.phone_outlined,
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Nomor telepon wajib diisi' : null,
            ),
          ),
        ),
      ),
    );

    // Sebelum disentuh tidak ada pesan apa pun.
    expect(find.text('Nomor telepon wajib diisi'), findsNothing);

    // Ketik lalu kosongkan supaya validasi berjalan.
    await tester.enterText(find.byType(TextField).first, 'a');
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();

    expect(find.text('Nomor telepon wajib diisi'), findsOneWidget);

    // Pesan berada di luar kotak: kotak berisi label, pesan tidak.
    final boxFinder = find.ancestor(
      of: find.text('Nomor telepon'),
      matching: find.byType(Container),
    );
    expect(
      find.descendant(of: boxFinder.first, matching: find.text('Nomor telepon wajib diisi')),
      findsNothing,
    );

    // Garis kotak memakai warna bahaya saat tidak valid.
    final box = tester.widget<Container>(boxFinder.first);
    final border = (box.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, AppColors.danger);
  });
}

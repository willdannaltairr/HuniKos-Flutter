import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'theme.dart';

/// Hasil satu kali percobaan membayar lewat Midtrans.
enum PaymentOutcome {
  /// Midtrans menyatakan pembayaran berhasil.
  paid,

  /// Pengguna belum menyelesaikan pembayaran, misalnya memilih VA lalu keluar.
  pending,

  /// Pembayaran ditolak atau dibatalkan.
  failed,

  /// Halaman Snap dibuka di browser (web). Status asli dicek dari backend
  /// setelah pengguna kembali.
  browserOpened,
}

/// Satu jembatan ke Midtrans untuk dua platform yang didukung aplikasi:
/// Android memakai SDK resmi, web memakai redirect_url.
class MidtransPayment {
  Future<PaymentOutcome> start({
    required String snapToken,
    required String redirectUrl,
  }) {
    return kIsWeb ? _startWeb(redirectUrl) : _startAndroid(snapToken);
  }

  Future<PaymentOutcome> _startWeb(String redirectUrl) async {
    final opened = await launchUrl(
      Uri.parse(redirectUrl),
      mode: LaunchMode.externalApplication,
    );
    return opened ? PaymentOutcome.browserOpened : PaymentOutcome.failed;
  }

  Future<PaymentOutcome> _startAndroid(String snapToken) async {
    // SDK menentukan lingkungan dari prefiks kunci client, bukan dari token.
    // Kunci produksi (`Mid-client-`) tidak bisa membuka token sandbox, jadi
    // kegagalannya dicegah di sini dengan pesan yang menyebut penyebabnya.
    final clientKey = AppConfig.midtransClientKey;
    final kunciProduksi = clientKey.startsWith('Mid-client-');
    if (!AppConfig.midtransIsProduction && kunciProduksi) {
      throw StateError(
        'Kunci Midtrans di aplikasi masih kunci produksi, sedangkan transaksi '
        'dibuat di sandbox. Isi MIDTRANS_CLIENT_KEY dengan kunci '
        'SB-Mid-client-... saat build, atau jalankan dengan '
        '--dart-define=MIDTRANS_IS_PRODUCTION=true bila memang produksi.',
      );
    }

    final sdk = await MidtransSDK.init(
      config: MidtransConfig(
        clientKey: clientKey,
        merchantBaseUrl: AppConfig.baseUrl,
        enableLog: kDebugMode,
        colorTheme: ColorTheme(
          colorPrimary: AppColors.gold,
          colorPrimaryDark: AppColors.goldDeep,
          colorSecondary: AppColors.navy,
        ),
      ),
    );

    // SDK memberi tahu hasil lewat callback setelah halaman Snap ditutup.
    // Completer menjembataninya ke Future yang bisa di-await layar.
    final selesai = Completer<PaymentOutcome>();
    sdk.setTransactionFinishedCallback((result) {
      if (selesai.isCompleted) return;
      final status = result.status.toLowerCase();
      if (status.contains('success')) {
        selesai.complete(PaymentOutcome.paid);
      } else if (status.contains('pending')) {
        selesai.complete(PaymentOutcome.pending);
      } else {
        selesai.complete(PaymentOutcome.failed);
      }
    });

    try {
      await sdk.startPaymentUiFlow(token: snapToken);
    } catch (_) {
      if (!selesai.isCompleted) selesai.complete(PaymentOutcome.failed);
    }

    // Pengguna bisa menutup halaman Snap tanpa memilih metode apa pun.
    return selesai.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => PaymentOutcome.pending,
    );
  }
}

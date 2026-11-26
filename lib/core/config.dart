/// Alamat backend diambil saat build supaya satu kode bisa dipakai untuk
/// emulator, perangkat fisik, dan server produksi.
///
/// Contoh:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
class AppConfig {
  const AppConfig._();

  static const String _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  /// Backend yang sudah online. Dipakai sebagai default di semua platform
  /// supaya aplikasi langsung tersambung tanpa perlu flag saat dijalankan.
  ///
  /// Saat mengembangkan backend di komputer sendiri, timpa lewat:
  ///   web/desktop : --dart-define=API_BASE_URL=http://localhost:3000
  ///   emulator    : --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String _productionUrl = 'https://hunikosbackend.vercel.app';

  /// Tanpa flag, semua platform memakai backend production. Alamat lokal hanya
  /// masuk lewat `--dart-define`, karena 10.0.2.2 adalah alias localhost
  /// komputer dari dalam emulator Android — bukan alamat yang bisa dipakai
  /// perangkat lain.
  static String get baseUrl => _fromEnvironment.isNotEmpty
      ? _fromEnvironment
      : _productionUrl;

  /// Render free plan bisa tidur, jadi request pertama diberi waktu lebih lega.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Setelah 6 detik loading, pengguna diberi tahu bahwa server sedang bangun.
  static const Duration slowServerThreshold = Duration(seconds: 6);

  static const int maxImageBytes = 2 * 1024 * 1024;
  static const int maxImagesPerRequest = 5;
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];

  /// Client key Midtrans boleh ada di aplikasi. Server key TIDAK, karena itu
  /// hanya dipakai backend untuk membuat transaksi dan memeriksa webhook.
  static const String _clientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    // Client key bersifat publik (boleh dibaca siapa pun), jadi aman dibundel.
    // Server key dan signature key TIDAK pernah masuk ke aplikasi.
    defaultValue: 'Mid-client-Cl8s5NqXJiH6C0cD',
  );

  static String get midtransClientKey => _clientKey;

  static const bool midtransIsProduction =
      bool.fromEnvironment('MIDTRANS_IS_PRODUCTION');
}

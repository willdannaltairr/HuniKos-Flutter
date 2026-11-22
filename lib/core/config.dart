import 'package:flutter/foundation.dart';

/// Alamat backend diambil saat build supaya satu kode bisa dipakai untuk
/// emulator, perangkat fisik, dan server produksi.
///
/// Contoh:
///   flutter run --dart-define=API_BASE_URL=https://hunikos-api.onrender.com
class AppConfig {
  const AppConfig._();

  static const String _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  /// Default hanya untuk pengembangan: emulator Android memakai 10.0.2.2,
  /// sedangkan web dan desktop boleh langsung memakai localhost. Port disamakan
  /// dengan `PORT` bawaan backend HuniKos (3000).
  static String get baseUrl {
    if (_fromEnvironment.isNotEmpty) return _fromEnvironment;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

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
}

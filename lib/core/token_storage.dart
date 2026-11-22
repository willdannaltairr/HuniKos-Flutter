import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token hanya disimpan di secure storage, tidak pernah di memori jangka
/// panjang selain cache kecil supaya interceptor tidak perlu async berulang.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'hunikos_token';
  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  /// Penyimpanan web butuh secure context. Bila platform menolak, aplikasi
  /// tetap jalan dengan token di memori sampai ditutup.
  bool _memoryOnly = false;

  String? get cachedToken => _cached;

  Future<String?> read() async {
    if (_loaded) return _cached;
    try {
      _cached = await _storage.read(key: _tokenKey);
    } catch (_) {
      _memoryOnly = true;
    }
    _loaded = true;
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    _loaded = true;
    if (_memoryOnly) return;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      _memoryOnly = true;
    }
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    if (_memoryOnly) return;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {
      _memoryOnly = true;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Masih membaca token dari secure storage saat aplikasi dibuka.
  checking,
  authenticated,
  unauthenticated,
}

/// Satu-satunya sumber kebenaran sesi: token, user, dan status login.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient api, required TokenStorage tokenStore})
      : _api = api,
        _tokens = tokenStore,
        _service = AuthService(api) {
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final TokenStorage _tokens;
  final AuthService _service;

  AuthStatus _status = AuthStatus.checking;
  User? _user;
  String? _sessionMessage;
  bool _submitting = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoggedIn => _status == AuthStatus.authenticated && _user != null;
  bool get isSubmitting => _submitting;
  String? get error => _error;
  Map<String, String> get fieldErrors => _fieldErrors;

  /// Pesan sekali pakai untuk layar login, misal setelah sesi berakhir.
  String? takeSessionMessage() {
    final message = _sessionMessage;
    _sessionMessage = null;
    return message;
  }

  /// Dipanggil sekali saat aplikasi dibuka: token lama langsung dipakai
  /// supaya pengguna tidak perlu login ulang setiap kali membuka aplikasi.
  Future<void> bootstrap() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      _user = await _service.me();
      _status = AuthStatus.authenticated;
    } on ApiException catch (error) {
      // 401 berarti token sudah tidak berlaku; error jaringan jangan
      // menghapus token karena server mungkin hanya sedang tidur.
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _tokens.clear();
        _status = AuthStatus.unauthenticated;
        // 403 datang dari akun yang dinonaktifkan admin, dan alasannya perlu
        // sampai ke layar login — bukan disembunyikan seperti token kedaluwarsa.
        if (error.statusCode == 403) _sessionMessage = error.message;
      } else {
        _status = AuthStatus.unauthenticated;
        _sessionMessage = error.message;
      }
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _runAuth(() async {
      final session = await _service.login(email: email, password: password);
      await _tokens.save(session.token);
      _user = session.user;
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    return _runAuth(() async {
      final session = await _service.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );
      await _tokens.save(session.token);
      _user = session.user;
      _status = AuthStatus.authenticated;
    });
  }

  Future<void> logout() async {
    await _tokens.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    _error = null;
    _fieldErrors = const {};
    _submitting = true;
    notifyListeners();

    try {
      _user = await _service.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _fieldErrors = error.fieldErrors;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<bool> uploadAvatar(XFile file) async {
    _error = null;
    _submitting = true;
    notifyListeners();

    try {
      _user = await _service.uploadAvatar(file);
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Dipanggil ApiClient ketika backend menjawab 401 pada endpoint ber-token.
  void _handleUnauthorized() {
    if (_status != AuthStatus.authenticated) return;
    _tokens.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _sessionMessage = 'Sesi berakhir, silakan masuk lagi';
    notifyListeners();
  }

  Future<bool> _runAuth(Future<void> Function() action) async {
    _error = null;
    _fieldErrors = const {};
    _submitting = true;
    notifyListeners();

    try {
      await action();
      return true;
    } on ApiException catch (error) {
      _error = error.message;
      _fieldErrors = error.fieldErrors;
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}

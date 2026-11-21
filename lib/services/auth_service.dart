import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/upload_utils.dart';
import '../models/user.dart';

/// Satu tempat untuk semua endpoint auth dan profil.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<({User user, String token})> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
  }) async {
    final payload = await _api.post('/api/auth/register', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
        'phone_number': phoneNumber.trim(),
    });
    return _readSession(payload);
  }

  Future<({User user, String token})> login({
    required String email,
    required String password,
  }) async {
    final payload = await _api.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _readSession(payload);
  }

  Future<User> me() async {
    final payload = await _api.get('/api/auth/me');
    return User.fromJson(payload.asMap);
  }

  Future<User> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    final payload = await _api.put('/api/users/me', body: {
      'full_name': fullName,
      // String kosong berarti pengguna menghapus nomor telepon.
      'phone_number': phoneNumber?.trim() ?? '',
    });
    return User.fromJson(payload.asMap);
  }

  Future<User> uploadAvatar(XFile file) async {
    final formData = FormData.fromMap({
      'avatar': await multipartFromXFile(file),
    });
    final payload = await _api.postMultipart('/api/users/me/avatar', formData);
    return User.fromJson(payload.asMap);
  }

  ({User user, String token}) _readSession(ApiPayload payload) {
    final data = payload.asMap;
    return (
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      token: data['token'] as String,
    );
  }
}

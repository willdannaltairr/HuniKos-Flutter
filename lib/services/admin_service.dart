import '../core/api_client.dart';
import '../core/api_meta.dart';
import '../models/dashboard.dart';
import '../models/property.dart';
import '../models/user.dart';

/// Endpoint admin: statistik platform, kelola pengguna, verifikasi properti.
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<AdminDashboard> dashboard() async {
    final payload = await _api.get('/api/admin/dashboard');
    return AdminDashboard.fromJson(payload.asMap);
  }

  Future<({List<User> users, ApiMeta meta})> users({
    String? role,
    String? accountStatus,
    String? q,
    int page = 1,
    int limit = 10,
  }) async {
    final payload = await _api.get('/api/admin/users', query: {
      'role': role,
      'account_status': accountStatus,
      'q': q,
      'page': page,
      'limit': limit,
    });
    return (
      users: payload.asList.map(User.fromJson).toList(growable: false),
      meta: payload.meta ??
          const ApiMeta(page: 1, limit: 10, total: 0, totalPages: 0),
    );
  }

  Future<User> changeUserStatus(String userId, String accountStatus) async {
    final payload = await _api.patch(
      '/api/admin/users/$userId/status',
      body: {'account_status': accountStatus},
    );
    return User.fromJson(payload.asMap);
  }

  Future<List<PropertyItem>> properties({
    required String verificationStatus,
  }) async {
    final payload = await _api.get(
      '/api/admin/properties',
      query: {'verification_status': verificationStatus},
    );
    return payload.asList.map(PropertyItem.fromJson).toList(growable: false);
  }

  Future<void> verifyProperty({
    required String propertyId,
    required String action,
    String? note,
  }) async {
    await _api.patch('/api/admin/properties/$propertyId/verification', body: {
      'action': action,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }
}

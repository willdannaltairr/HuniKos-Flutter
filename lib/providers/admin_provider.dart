import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/api_meta.dart';
import '../models/dashboard.dart';
import '../models/property.dart';
import '../models/user.dart';
import '../services/admin_service.dart';

/// State area admin: statistik, verifikasi properti, dan kelola pengguna.
class AdminProvider extends ChangeNotifier {
  AdminProvider(this._service);

  final AdminService _service;

  AdminDashboard? _dashboard;
  bool _loadingDashboard = false;
  String? _dashboardError;

  final List<PropertyItem> _properties = [];
  String _verificationFilter = 'pending';
  bool _loadingProperties = false;
  String? _propertiesError;

  final List<User> _users = [];
  ApiMeta _usersMeta = const ApiMeta(page: 1, limit: 10, total: 0, totalPages: 0);
  String? _roleFilter;
  String? _statusFilter;
  String _userQuery = '';
  bool _loadingUsers = false;
  String? _usersError;

  AdminDashboard? get dashboard => _dashboard;
  bool get loadingDashboard => _loadingDashboard;
  String? get dashboardError => _dashboardError;

  List<PropertyItem> get properties => List.unmodifiable(_properties);
  String get verificationFilter => _verificationFilter;
  bool get loadingProperties => _loadingProperties;
  String? get propertiesError => _propertiesError;

  List<User> get users => List.unmodifiable(_users);
  ApiMeta get usersMeta => _usersMeta;
  String? get roleFilter => _roleFilter;
  String? get statusFilter => _statusFilter;
  String get userQuery => _userQuery;
  bool get loadingUsers => _loadingUsers;
  String? get usersError => _usersError;
  bool get hasMoreUsers => _usersMeta.hasNextPage;

  Future<void> loadDashboard() async {
    _loadingDashboard = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.dashboard();
    } on ApiException catch (error) {
      _dashboardError = error.message;
    } finally {
      _loadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadProperties({String? status}) async {
    if (status != null) _verificationFilter = status;
    _loadingProperties = true;
    _propertiesError = null;
    notifyListeners();
    try {
      final result = await _service.properties(
        verificationStatus: _verificationFilter,
      );
      _properties
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _propertiesError = error.message;
    } finally {
      _loadingProperties = false;
      notifyListeners();
    }
  }

  Future<String?> verifyProperty({
    required String propertyId,
    required String action,
    String? note,
  }) async {
    try {
      await _service.verifyProperty(
        propertyId: propertyId,
        action: action,
        note: note,
      );
      await loadProperties();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadUsers({
    String? role,
    String? accountStatus,
    String? query,
    bool reset = true,
  }) async {
    if (reset) {
      _roleFilter = role;
      _statusFilter = accountStatus;
      _userQuery = query ?? '';
      _users.clear();
    }
    _loadingUsers = true;
    _usersError = null;
    notifyListeners();

    try {
      final result = await _service.users(
        role: _roleFilter,
        accountStatus: _statusFilter,
        q: _userQuery,
        page: reset ? 1 : _usersMeta.page + 1,
      );
      if (reset) _users.clear();
      _users.addAll(result.users);
      _usersMeta = result.meta;
    } on ApiException catch (error) {
      _usersError = error.message;
    } finally {
      _loadingUsers = false;
      notifyListeners();
    }
  }

  Future<String?> changeUserStatus(String userId, String status) async {
    try {
      final updated = await _service.changeUserStatus(userId, status);
      final index = _users.indexWhere((user) => user.id == userId);
      if (index >= 0) _users[index] = updated;
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }
}

import '../core/json_utils.dart';

/// Bentuk User dari kontrak bagian 8.
class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.accountStatus,
    this.phoneNumber,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final String role;
  final String accountStatus;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? createdAt;

  bool get isTenant => role == 'tenant';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isSuspended => accountStatus == 'suspended';

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String get roleLabel {
    switch (role) {
      case 'owner':
        return 'Pemilik';
      case 'admin':
        return 'Admin';
      default:
        return 'Penyewa';
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: asString(json['id']) ?? '',
      fullName: asString(json['full_name']) ?? '-',
      email: asString(json['email']) ?? '-',
      role: asString(json['role']) ?? 'tenant',
      accountStatus: asString(json['account_status']) ?? 'active',
      phoneNumber: asString(json['phone_number']),
      avatarUrl: asString(json['avatar_url']),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'account_status': accountStatus,
        'phone_number': phoneNumber,
        'avatar_url': avatarUrl,
        'created_at': createdAt?.toIso8601String(),
      };
}

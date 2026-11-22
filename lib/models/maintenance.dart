import '../core/json_utils.dart';

class Maintenance {
  const Maintenance({
    required this.id,
    required this.bookingId,
    required this.roomId,
    required this.title,
    required this.description,
    required this.status,
    required this.roomNumber,
    required this.propertyName,
    required this.tenantName,
    this.photoUrl,
    this.ownerNote,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String bookingId;
  final String roomId;
  final String title;
  final String description;
  final String status;
  final String roomNumber;
  final String propertyName;
  final String tenantName;
  final String? photoUrl;
  final String? ownerNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    return Maintenance(
      id: asString(json['id']) ?? '',
      bookingId: asString(json['booking_id']) ?? '',
      roomId: asString(json['room_id']) ?? '',
      title: asString(json['title']) ?? '-',
      description: asString(json['description']) ?? '',
      status: asString(json['status']) ?? 'OPEN',
      roomNumber: asString(json['room_number']) ?? '-',
      propertyName: asString(json['property_name']) ?? '-',
      tenantName: asString(json['tenant_name']) ?? '-',
      photoUrl: asString(json['photo_url']),
      ownerNote: asString(json['owner_note']),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
      updatedAt: DateTime.tryParse(asString(json['updated_at']) ?? ''),
    );
  }
}

class MaintenanceStatus {
  const MaintenanceStatus._();

  static const all = ['OPEN', 'IN_PROGRESS', 'DONE'];

  /// Urutan perpindahan status yang wajar ditawarkan ke pemilik.
  static String? next(String current) {
    switch (current) {
      case 'OPEN':
        return 'IN_PROGRESS';
      case 'IN_PROGRESS':
        return 'DONE';
      default:
        return null;
    }
  }

  static String label(String status) {
    switch (status) {
      case 'OPEN':
        return 'Terbuka';
      case 'IN_PROGRESS':
        return 'Dikerjakan';
      case 'DONE':
        return 'Selesai';
      default:
        return status;
    }
  }
}

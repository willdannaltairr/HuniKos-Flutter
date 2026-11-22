import '../core/json_utils.dart';

class BookingRoom {
  const BookingRoom({required this.id, required this.roomNumber, required this.roomType});

  final String id;
  final String roomNumber;
  final String roomType;

  factory BookingRoom.fromJson(Map<String, dynamic> json) {
    return BookingRoom(
      id: asString(json['id']) ?? '',
      roomNumber: asString(json['room_number']) ?? '-',
      roomType: asString(json['room_type']) ?? '-',
    );
  }
}

class BookingProperty {
  const BookingProperty({required this.id, required this.name, required this.city});

  final String id;
  final String name;
  final String city;

  factory BookingProperty.fromJson(Map<String, dynamic> json) {
    return BookingProperty(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '-',
      city: asString(json['city']) ?? '-',
    );
  }
}

class BookingTenant {
  const BookingTenant({required this.id, required this.fullName, this.phoneNumber});

  final String id;
  final String fullName;
  final String? phoneNumber;

  factory BookingTenant.fromJson(Map<String, dynamic> json) {
    return BookingTenant(
      id: asString(json['id']) ?? '',
      fullName: asString(json['full_name']) ?? '-',
      phoneNumber: asString(json['phone_number']),
    );
  }
}

/// Status booking dipakai sebagai chip berwarna di banyak layar.
class BookingStatus {
  const BookingStatus._();

  static const all = [
    'PENDING',
    'AWAITING_PAYMENT',
    'CONFIRMED',
    'REJECTED',
    'CANCELLED',
    'EXPIRED',
    'COMPLETED',
  ];

  static const active = ['PENDING', 'AWAITING_PAYMENT', 'CONFIRMED'];

  static String label(String status) {
    switch (status) {
      case 'PENDING':
        return 'Menunggu persetujuan';
      case 'AWAITING_PAYMENT':
        return 'Menunggu pembayaran';
      case 'CONFIRMED':
        return 'Dikonfirmasi';
      case 'REJECTED':
        return 'Ditolak';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'EXPIRED':
        return 'Kedaluwarsa';
      case 'COMPLETED':
        return 'Selesai';
      default:
        return status;
    }
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.durationMonths,
    required this.rentalPriceSnapshot,
    required this.totalAmount,
    required this.room,
    required this.property,
    required this.tenant,
    this.note,
    this.ownerNote,
    this.expiresAt,
    this.createdAt,
    this.latestPaymentStatus,
  });

  final String id;
  final String bookingCode;
  final String status;
  final String startDate;
  final String endDate;
  final int durationMonths;
  final double rentalPriceSnapshot;
  final double totalAmount;
  final BookingRoom room;
  final BookingProperty property;
  final BookingTenant tenant;
  final String? note;
  final String? ownerNote;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final String? latestPaymentStatus;

  bool get canCancel => status == 'PENDING' || status == 'AWAITING_PAYMENT';
  bool get canUploadProof => status == 'AWAITING_PAYMENT';
  bool get canDecide => status == 'PENDING';
  bool get canComplete => status == 'CONFIRMED';

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: asString(json['id']) ?? '',
      bookingCode: asString(json['booking_code']) ?? '-',
      status: asString(json['status']) ?? 'PENDING',
      startDate: asString(json['start_date']) ?? '',
      endDate: asString(json['end_date']) ?? '',
      durationMonths: asInt(json['duration_months']) ?? 1,
      rentalPriceSnapshot: asDouble(json['rental_price_snapshot']) ?? 0,
      totalAmount: asDouble(json['total_amount']) ?? 0,
      room: BookingRoom.fromJson(asMap(json['room']) ?? const {}),
      property: BookingProperty.fromJson(asMap(json['property']) ?? const {}),
      tenant: BookingTenant.fromJson(asMap(json['tenant']) ?? const {}),
      note: asString(json['note']),
      ownerNote: asString(json['owner_note']),
      expiresAt: DateTime.tryParse(asString(json['expires_at']) ?? ''),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
      latestPaymentStatus: asString(json['latest_payment_status']),
    );
  }
}

import '../core/json_utils.dart';

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.proofUrl,
    required this.status,
    required this.bookingCode,
    required this.roomNumber,
    required this.propertyName,
    required this.tenantName,
    this.note,
    this.verifiedAt,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final double amount;
  final String proofUrl;
  final String status;
  final String bookingCode;
  final String roomNumber;
  final String propertyName;
  final String tenantName;
  final String? note;
  final DateTime? verifiedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING';

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: asString(json['id']) ?? '',
      bookingId: asString(json['booking_id']) ?? '',
      amount: asDouble(json['amount']) ?? 0,
      proofUrl: asString(json['proof_url']) ?? '',
      status: asString(json['status']) ?? 'PENDING',
      // Pada detail booking, backend hanya mengirim kolom tabel pembayaran,
      // jadi nama-nama tambahan ini boleh kosong.
      bookingCode: asString(json['booking_code']) ?? '-',
      roomNumber: asString(json['room_number']) ?? '-',
      propertyName: asString(json['property_name']) ?? '-',
      tenantName: asString(json['tenant_name']) ?? '-',
      note: asString(json['note']),
      verifiedAt: DateTime.tryParse(asString(json['verified_at']) ?? ''),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
    );
  }
}

class PaymentStatus {
  const PaymentStatus._();

  static const all = ['PENDING', 'VERIFIED', 'REJECTED'];

  static String label(String status) {
    switch (status) {
      case 'PENDING':
        return 'Menunggu verifikasi';
      case 'VERIFIED':
        return 'Terverifikasi';
      case 'REJECTED':
        return 'Ditolak';
      default:
        return status;
    }
  }
}

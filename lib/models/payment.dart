import '../core/json_utils.dart';

/// Satu pembayaran. Sejak memakai Midtrans Snap, bukti transfer tidak dipakai
/// lagi: status Pembayaran ditentukan oleh webhook Midtrans.
class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.bookingCode,
    required this.roomNumber,
    required this.propertyName,
    required this.tenantName,
    this.proofUrl,
    this.midtransOrderId,
    this.midtransTransactionStatus,
    this.midtransPaymentType,
    this.note,
    this.verifiedAt,
    this.createdAt,
  });

  final String id;
  final String bookingId;
  final double amount;
  final String status;
  final String bookingCode;
  final String roomNumber;
  final String propertyName;
  final String tenantName;

  /// Diisi hanya untuk data lama yang masih memakai bukti transfer.
  final String? proofUrl;

  final String? midtransOrderId;
  final String? midtransTransactionStatus;
  final String? midtransPaymentType;

  final String? note;
  final DateTime? verifiedAt;
  final DateTime? createdAt;

  bool get isPending => status == 'PENDING';
  bool get fromMidtrans => midtransOrderId != null && midtransOrderId!.isNotEmpty;

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: asString(json['id']) ?? '',
      bookingId: asString(json['booking_id']) ?? '',
      amount: asDouble(json['amount']) ?? 0,
      status: asString(json['status']) ?? 'PENDING',
      // Nama-nama tambahan kosong pada detail booking, itu wajar.
      bookingCode: asString(json['booking_code']) ?? '-',
      roomNumber: asString(json['room_number']) ?? '-',
      propertyName: asString(json['property_name']) ?? '-',
      tenantName: asString(json['tenant_name']) ?? '-',
      proofUrl: asString(json['proof_url']),
      midtransOrderId: asString(json['midtrans_order_id']),
      midtransTransactionStatus: asString(json['midtrans_transaction_status']),
      midtransPaymentType: asString(json['midtrans_payment_type']),
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
        return 'Menunggu pembayaran';
      case 'VERIFIED':
        return 'Lunas';
      case 'REJECTED':
        return 'Gagal / dibatalkan';
      default:
        return status;
    }
  }
}

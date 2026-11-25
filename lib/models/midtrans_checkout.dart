import '../core/json_utils.dart';

/// Data yang dikirim backend untuk memulai pembayaran lewat Midtrans Snap.
/// Server yang menentukan nominal dan order id, aplikasi hanya menampilkan.
class MidtransCheckout {
  const MidtransCheckout({
    required this.paymentId,
    required this.orderId,
    required this.snapToken,
    required this.redirectUrl,
    required this.amount,
    required this.bookingCode,
  });

  final String paymentId;
  final String orderId;
  final String snapToken;
  final String redirectUrl;
  final double amount;
  final String bookingCode;

  factory MidtransCheckout.fromJson(Map<String, dynamic> json) {
    return MidtransCheckout(
      paymentId: asString(json['payment_id']) ?? '',
      orderId: asString(json['order_id']) ?? '',
      snapToken: asString(json['snap_token']) ?? '',
      redirectUrl: asString(json['redirect_url']) ?? '',
      amount: asDouble(json['amount']) ?? 0,
      bookingCode: asString(json['booking_code']) ?? '-',
    );
  }
}

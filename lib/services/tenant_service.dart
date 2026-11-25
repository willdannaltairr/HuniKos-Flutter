import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/upload_utils.dart';
import '../models/booking.dart';
import '../models/booking_detail.dart';
import '../models/maintenance.dart';
import '../models/midtrans_checkout.dart';
import '../models/payment.dart';

/// Endpoint milik penyewa: booking, bukti pembayaran, dan laporan kerusakan.
class TenantService {
  TenantService(this._api);

  final ApiClient _api;

  Future<Booking> createBooking({
    required String roomId,
    required String startDate,
    required int durationMonths,
    String? note,
  }) async {
    final payload = await _api.post('/api/bookings', body: {
      'room_id': roomId,
      'start_date': startDate,
      'duration_months': durationMonths,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return Booking.fromJson(payload.asMap);
  }

  Future<List<Booking>> myBookings({String? status}) async {
    final payload = await _api.get('/api/bookings', query: {'status': status});
    return payload.asList.map(Booking.fromJson).toList(growable: false);
  }

  Future<BookingDetail> bookingDetail(String id) async {
    final payload = await _api.get('/api/bookings/$id');
    return BookingDetail.fromJson(payload.asMap);
  }

  Future<Booking> cancelBooking(String id) async {
    final payload = await _api.patch('/api/bookings/$id/cancel');
    return Booking.fromJson(payload.asMap);
  }

  Future<Payment> uploadProof(String bookingId, XFile file) async {
    final formData = FormData.fromMap({
      'proof': await multipartFromXFile(file),
    });
    final payload =
        await _api.postMultipart('/api/bookings/$bookingId/payments', formData);
    return Payment.fromJson(payload.asMap);
  }

  /// Membuat transaksi Snap. Nominal ditentukan backend dari booking.
  Future<MidtransCheckout> createMidtransCheckout(String bookingId) async {
    final payload = await _api.post('/api/bookings/$bookingId/payments/midtrans');
    return MidtransCheckout.fromJson(payload.asMap);
  }

  /// Backend mengecek status asli ke Midtrans, lalu memperbarui booking.
  Future<void> syncMidtransPayment(String bookingId) async {
    await _api.get('/api/bookings/$bookingId/payments/midtrans/status');
  }

  Future<List<Payment>> myPayments() async {
    final payload = await _api.get('/api/payments');
    return payload.asList.map(Payment.fromJson).toList(growable: false);
  }

  Future<List<Maintenance>> myMaintenance() async {
    final payload = await _api.get('/api/maintenance');
    return payload.asList.map(Maintenance.fromJson).toList(growable: false);
  }

  Future<Maintenance> createMaintenance({
    required String bookingId,
    required String title,
    required String description,
    XFile? photo,
  }) async {
    final formData = FormData.fromMap({
      'booking_id': bookingId,
      'title': title,
      'description': description,
      if (photo != null) 'photo': await multipartFromXFile(photo),
    });
    final payload = await _api.postMultipart('/api/maintenance', formData);
    return Maintenance.fromJson(payload.asMap);
  }
}

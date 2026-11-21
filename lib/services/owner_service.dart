import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../core/upload_utils.dart';
import '../models/booking.dart';
import '../models/dashboard.dart';
import '../models/maintenance.dart';
import '../models/payment.dart';
import '../models/property.dart';

/// Endpoint pemilik. Semua data di sini otomatis terbatas pada milik pemilik
/// yang sedang login, jadi tidak perlu mengirim owner_id dari client.
class OwnerService {
  OwnerService(this._api);

  final ApiClient _api;

  Future<OwnerDashboard> dashboard() async {
    final payload = await _api.get('/api/owner/dashboard');
    return OwnerDashboard.fromJson(payload.asMap);
  }

  // --- Properti ---

  Future<List<PropertyItem>> properties() async {
    final payload = await _api.get('/api/owner/properties');
    return payload.asList.map(PropertyItem.fromJson).toList(growable: false);
  }

  Future<Map<String, dynamic>> createProperty(Map<String, dynamic> body) async {
    final payload = await _api.post('/api/owner/properties', body: body);
    return payload.asMap;
  }

  Future<Map<String, dynamic>> updateProperty(
    String id,
    Map<String, dynamic> body,
  ) async {
    final payload = await _api.put('/api/owner/properties/$id', body: body);
    return payload.asMap;
  }

  Future<void> deleteProperty(String id) async {
    await _api.delete('/api/owner/properties/$id');
  }

  Future<List<PropertyImage>> uploadPropertyImages(
    String propertyId,
    List<XFile> files, {
    String? roomId,
  }) async {
    final formData = FormData.fromMap({
      'images': await Future.wait(files.map(multipartFromXFile)),
      if (roomId != null && roomId.isNotEmpty) 'room_id': roomId,
    });
    final payload = await _api.postMultipart(
      '/api/owner/properties/$propertyId/images',
      formData,
    );
    return payload.asList
        .map(PropertyImage.fromJson)
        .toList(growable: false);
  }

  Future<void> deleteImage(String imageId) async {
    await _api.delete('/api/owner/images/$imageId');
  }

  Future<void> setCoverImage(String imageId) async {
    await _api.patch('/api/owner/images/$imageId/cover');
  }

  // --- Kamar ---

  Future<List<RoomItem>> rooms(String propertyId) async {
    final payload =
        await _api.get('/api/owner/properties/$propertyId/rooms');
    return payload.asList.map(RoomItem.fromJson).toList(growable: false);
  }

  Future<RoomItem?> createRoom(
    String propertyId,
    Map<String, dynamic> body,
  ) async {
    final payload = await _api.post(
      '/api/owner/properties/$propertyId/rooms',
      body: body,
    );
    final data = payload.data;
    if (data is Map<String, dynamic>) return RoomItem.fromJson(data);
    return null;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> body) async {
    await _api.put('/api/owner/rooms/$roomId', body: body);
  }

  Future<void> deleteRoom(String roomId) async {
    await _api.delete('/api/owner/rooms/$roomId');
  }

  // --- Booking ---

  Future<List<Booking>> bookings({String? status}) async {
    final payload = await _api.get('/api/owner/bookings', query: {'status': status});
    return payload.asList.map(Booking.fromJson).toList(growable: false);
  }

  Future<Booking> decideBooking({
    required String bookingId,
    required String action,
    String? ownerNote,
  }) async {
    final payload = await _api.patch(
      '/api/owner/bookings/$bookingId/decision',
      body: {
        'action': action,
        if (ownerNote != null && ownerNote.trim().isNotEmpty)
          'owner_note': ownerNote.trim(),
      },
    );
    return Booking.fromJson(payload.asMap);
  }

  Future<Booking> completeBooking(String bookingId) async {
    final payload =
        await _api.patch('/api/owner/bookings/$bookingId/complete');
    return Booking.fromJson(payload.asMap);
  }

  // --- Pembayaran ---

  Future<List<Payment>> payments({String? status}) async {
    final payload =
        await _api.get('/api/owner/payments', query: {'status': status});
    return payload.asList.map(Payment.fromJson).toList(growable: false);
  }

  Future<Payment> verifyPayment({
    required String paymentId,
    required String action,
    String? note,
  }) async {
    final payload = await _api.patch(
      '/api/owner/payments/$paymentId/verify',
      body: {
        'action': action,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return Payment.fromJson(payload.asMap);
  }

  // --- Laporan kerusakan ---

  Future<List<Maintenance>> maintenance({String? status}) async {
    final payload =
        await _api.get('/api/owner/maintenance', query: {'status': status});
    return payload.asList.map(Maintenance.fromJson).toList(growable: false);
  }

  Future<Maintenance> updateMaintenance({
    required String id,
    required String status,
    String? ownerNote,
  }) async {
    final payload = await _api.patch('/api/owner/maintenance/$id', body: {
      'status': status,
      if (ownerNote != null && ownerNote.trim().isNotEmpty)
        'owner_note': ownerNote.trim(),
    });
    return Maintenance.fromJson(payload.asMap);
  }
}

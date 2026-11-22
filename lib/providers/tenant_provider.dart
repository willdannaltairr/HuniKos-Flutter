import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../models/booking.dart';
import '../models/booking_detail.dart';
import '../models/maintenance.dart';
import '../models/payment.dart';
import '../services/tenant_service.dart';

/// State penyewa: daftar booking, detail booking, dan laporan kerusakan.
class TenantProvider extends ChangeNotifier {
  TenantProvider(this._service);

  final TenantService _service;

  final List<Booking> _bookings = [];
  String? _statusFilter;
  bool _loadingBookings = false;
  String? _bookingsError;

  BookingDetail? _detail;
  bool _loadingDetail = false;
  String? _detailError;

  final List<Maintenance> _maintenance = [];
  bool _loadingMaintenance = false;
  String? _maintenanceError;

  List<Booking> get bookings => List.unmodifiable(_bookings);
  String? get statusFilter => _statusFilter;
  bool get loadingBookings => _loadingBookings;
  String? get bookingsError => _bookingsError;

  BookingDetail? get detail => _detail;
  bool get loadingDetail => _loadingDetail;
  String? get detailError => _detailError;

  List<Maintenance> get maintenance => List.unmodifiable(_maintenance);
  bool get loadingMaintenance => _loadingMaintenance;
  String? get maintenanceError => _maintenanceError;

  /// Booking CONFIRMED dipakai sebagai pilihan pada form laporan kerusakan.
  List<Booking> get confirmedBookings =>
      _bookings.where((booking) => booking.status == 'CONFIRMED').toList();

  Future<void> loadBookings({String? status, bool keepFilter = false}) async {
    if (!keepFilter) _statusFilter = status;
    _loadingBookings = true;
    _bookingsError = null;
    notifyListeners();

    try {
      final result = await _service.myBookings(status: _statusFilter);
      _bookings
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _bookingsError = error.message;
    } finally {
      _loadingBookings = false;
      notifyListeners();
    }
  }

  /// Dipakai form laporan: butuh daftar booking CONFIRMED tanpa mengubah
  /// filter yang sedang aktif di tab booking.
  Future<List<Booking>> fetchConfirmedBookings() async {
    try {
      return await _service.myBookings(status: 'CONFIRMED');
    } on ApiException {
      return const [];
    }
  }

  Future<void> loadDetail(String id) async {
    _loadingDetail = true;
    _detailError = null;
    notifyListeners();

    try {
      _detail = await _service.bookingDetail(id);
    } on ApiException catch (error) {
      _detailError = error.message;
      _detail = null;
    } finally {
      _loadingDetail = false;
      notifyListeners();
    }
  }

  Future<String?> cancelBooking(String id) async {
    try {
      await _service.cancelBooking(id);
      await loadBookings(keepFilter: true);
      await loadDetail(id);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<Booking> createBooking({
    required String roomId,
    required String startDate,
    required int durationMonths,
    String? note,
  }) {
    return _service.createBooking(
      roomId: roomId,
      startDate: startDate,
      durationMonths: durationMonths,
      note: note,
    );
  }

  Future<String?> uploadProof(String bookingId, XFile file) async {
    try {
      await _service.uploadProof(bookingId, file);
      await loadDetail(bookingId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadMaintenance() async {
    _loadingMaintenance = true;
    _maintenanceError = null;
    notifyListeners();

    try {
      final result = await _service.myMaintenance();
      _maintenance
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _maintenanceError = error.message;
    } finally {
      _loadingMaintenance = false;
      notifyListeners();
    }
  }

  Future<String?> createMaintenance({
    required String bookingId,
    required String title,
    required String description,
    XFile? photo,
  }) async {
    try {
      await _service.createMaintenance(
        bookingId: bookingId,
        title: title,
        description: description,
        photo: photo,
      );
      await loadMaintenance();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Payment? latestPendingPayment(BookingDetail detail) {
    for (final payment in detail.payments) {
      if (payment.isPending) return payment;
    }
    return null;
  }
}

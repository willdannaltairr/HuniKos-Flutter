import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../models/booking.dart';
import '../models/booking_detail.dart';
import '../models/maintenance.dart';
import '../models/midtrans_checkout.dart';
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

  final List<Payment> _payments = [];
  bool _loadingPayments = false;
  String? _paymentsError;

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

  List<Payment> get payments => List.unmodifiable(_payments);
  bool get loadingPayments => _loadingPayments;
  String? get paymentsError => _paymentsError;

  /// Dipakai ringkasan keuangan di profil: total yang sudah lunas dan yang
  /// dibayar bulan berjalan.
  double get totalSpent => _payments
      .where((payment) => payment.status == 'VERIFIED')
      .fold(0, (sum, payment) => sum + payment.amount);

  double get spentThisMonth {
    final now = DateTime.now();
    return _payments
        .where((payment) =>
            payment.status == 'VERIFIED' &&
            payment.verifiedAt != null &&
            payment.verifiedAt!.year == now.year &&
            payment.verifiedAt!.month == now.month)
        .fold(0, (sum, payment) => sum + payment.amount);
  }

  int get activeBookingCount => _bookings
      .where((booking) => BookingStatus.active.contains(booking.status))
      .length;

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

  /// Membuat transaksi Snap. Nominal dan order id ditentukan backend.
  Future<MidtransCheckout> createMidtransCheckout(String bookingId) {
    return _service.createMidtransCheckout(bookingId);
  }

  /// Tanyakan status asli ke Midtrans lewat backend, lalu muat ulang detail.
  Future<void> syncMidtransPayment(String bookingId) async {
    await _service.syncMidtransPayment(bookingId);
    await loadDetail(bookingId);
  }

  Future<void> loadPayments() async {
    _loadingPayments = true;
    _paymentsError = null;
    notifyListeners();

    try {
      final result = await _service.myPayments();
      _payments
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _paymentsError = error.message;
    } finally {
      _loadingPayments = false;
      notifyListeners();
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

  /// Dikosongkan saat sesi berakhir. Tanpa ini, akun berikutnya di perangkat
  /// yang sama masih melihat booking dan laporan milik akun sebelumnya.
  void reset() {
    _bookings.clear();
    _statusFilter = null;
    _loadingBookings = false;
    _bookingsError = null;
    _detail = null;
    _loadingDetail = false;
    _detailError = null;
    _maintenance.clear();
    _loadingMaintenance = false;
    _maintenanceError = null;
    _payments.clear();
    _loadingPayments = false;
    _paymentsError = null;
    notifyListeners();
  }

  Payment? latestPendingPayment(BookingDetail detail) {
    for (final payment in detail.payments) {
      if (payment.isPending) return payment;
    }
    return null;
  }
}

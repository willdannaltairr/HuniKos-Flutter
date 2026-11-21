import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_exception.dart';
import '../models/booking.dart';
import '../models/dashboard.dart';
import '../models/maintenance.dart';
import '../models/payment.dart';
import '../models/property.dart';
import '../services/owner_service.dart';

/// State area pemilik. Setiap daftar punya status loading/error sendiri agar
/// satu tab yang gagal tidak mengosongkan tab lain.
class OwnerProvider extends ChangeNotifier {
  OwnerProvider(this._service);

  final OwnerService _service;

  OwnerDashboard? _dashboard;
  bool _loadingDashboard = false;
  String? _dashboardError;

  final List<PropertyItem> _properties = [];
  bool _loadingProperties = false;
  String? _propertiesError;

  final List<RoomItem> _rooms = [];
  bool _loadingRooms = false;
  String? _roomsError;

  final List<Booking> _bookings = [];
  String? _bookingFilter;
  bool _loadingBookings = false;
  String? _bookingsError;

  final List<Payment> _payments = [];
  String? _paymentFilter;
  bool _loadingPayments = false;
  String? _paymentsError;

  final List<Maintenance> _maintenance = [];
  String? _maintenanceFilter;
  bool _loadingMaintenance = false;
  String? _maintenanceError;

  OwnerDashboard? get dashboard => _dashboard;
  bool get loadingDashboard => _loadingDashboard;
  String? get dashboardError => _dashboardError;

  List<PropertyItem> get properties => List.unmodifiable(_properties);
  bool get loadingProperties => _loadingProperties;
  String? get propertiesError => _propertiesError;

  List<RoomItem> get rooms => List.unmodifiable(_rooms);
  bool get loadingRooms => _loadingRooms;
  String? get roomsError => _roomsError;

  List<Booking> get bookings => List.unmodifiable(_bookings);
  String? get bookingFilter => _bookingFilter;
  bool get loadingBookings => _loadingBookings;
  String? get bookingsError => _bookingsError;

  List<Payment> get payments => List.unmodifiable(_payments);
  String? get paymentFilter => _paymentFilter;
  bool get loadingPayments => _loadingPayments;
  String? get paymentsError => _paymentsError;

  List<Maintenance> get maintenance => List.unmodifiable(_maintenance);
  String? get maintenanceFilter => _maintenanceFilter;
  bool get loadingMaintenance => _loadingMaintenance;
  String? get maintenanceError => _maintenanceError;

  Future<void> loadDashboard() async {
    _loadingDashboard = true;
    _dashboardError = null;
    notifyListeners();
    try {
      _dashboard = await _service.dashboard();
    } on ApiException catch (error) {
      _dashboardError = error.message;
    } finally {
      _loadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadProperties() async {
    _loadingProperties = true;
    _propertiesError = null;
    notifyListeners();
    try {
      final result = await _service.properties();
      _properties
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _propertiesError = error.message;
    } finally {
      _loadingProperties = false;
      notifyListeners();
    }
  }

  /// Null berarti berhasil; selain itu pesan yang siap ditampilkan.
  Future<String?> createProperty(Map<String, dynamic> body) async {
    try {
      await _service.createProperty(body);
      await loadProperties();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateProperty(String id, Map<String, dynamic> body) async {
    try {
      await _service.updateProperty(id, body);
      await loadProperties();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteProperty(String id) async {
    try {
      await _service.deleteProperty(id);
      _properties.removeWhere((property) => property.id == id);
      notifyListeners();
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> uploadImages(
    String propertyId,
    List<XFile> files, {
    String? roomId,
  }) async {
    try {
      await _service.uploadPropertyImages(propertyId, files, roomId: roomId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteImage(String imageId) async {
    try {
      await _service.deleteImage(imageId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> setCover(String imageId) async {
    try {
      await _service.setCoverImage(imageId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadRooms(String propertyId) async {
    _loadingRooms = true;
    _roomsError = null;
    notifyListeners();
    try {
      final result = await _service.rooms(propertyId);
      _rooms
        ..clear()
        ..addAll(result);
    } on ApiException catch (error) {
      _roomsError = error.message;
    } finally {
      _loadingRooms = false;
      notifyListeners();
    }
  }

  Future<String?> createRoom(String propertyId, Map<String, dynamic> body) async {
    try {
      await _service.createRoom(propertyId, body);
      await loadRooms(propertyId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> updateRoom(
    String roomId,
    String propertyId,
    Map<String, dynamic> body,
  ) async {
    try {
      await _service.updateRoom(roomId, body);
      await loadRooms(propertyId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> deleteRoom(String roomId, String propertyId) async {
    try {
      await _service.deleteRoom(roomId);
      await loadRooms(propertyId);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadBookings({String? status}) async {
    _bookingFilter = status;
    _loadingBookings = true;
    _bookingsError = null;
    notifyListeners();
    try {
      final result = await _service.bookings(status: status);
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

  Future<String?> decideBooking({
    required String bookingId,
    required String action,
    String? note,
  }) async {
    try {
      await _service.decideBooking(
        bookingId: bookingId,
        action: action,
        ownerNote: note,
      );
      await loadBookings(status: _bookingFilter);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> completeBooking(String bookingId) async {
    try {
      await _service.completeBooking(bookingId);
      await loadBookings(status: _bookingFilter);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadPayments({String? status}) async {
    _paymentFilter = status;
    _loadingPayments = true;
    _paymentsError = null;
    notifyListeners();
    try {
      final result = await _service.payments(status: status);
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

  Future<String?> verifyPayment({
    required String paymentId,
    required String action,
    String? note,
  }) async {
    try {
      await _service.verifyPayment(paymentId: paymentId, action: action, note: note);
      await loadPayments(status: _paymentFilter);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<void> loadMaintenance({String? status}) async {
    _maintenanceFilter = status;
    _loadingMaintenance = true;
    _maintenanceError = null;
    notifyListeners();
    try {
      final result = await _service.maintenance(status: status);
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

  Future<String?> updateMaintenance({
    required String id,
    required String status,
    String? note,
  }) async {
    try {
      await _service.updateMaintenance(id: id, status: status, ownerNote: note);
      await loadMaintenance(status: _maintenanceFilter);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  void clearRooms() {
    _rooms.clear();
    _roomsError = null;
    notifyListeners();
  }
}

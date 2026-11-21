import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../core/api_meta.dart';
import '../models/facility.dart';
import '../models/property.dart';
import '../models/room_detail.dart';
import '../services/catalog_service.dart';

/// Filter aktif layar Explore. Disimpan di sini supaya chip dan bottom sheet
/// membaca nilai yang sama.
class PropertyFilter {
  const PropertyFilter({
    this.city,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.facilityIds = const [],
    this.availableOnly = false,
    this.sort = 'newest',
  });

  final String? city;
  final String? type;
  final double? minPrice;
  final double? maxPrice;
  final List<String> facilityIds;
  final bool availableOnly;
  final String sort;

  bool get isActive =>
      (city?.isNotEmpty ?? false) ||
      type != null ||
      minPrice != null ||
      maxPrice != null ||
      facilityIds.isNotEmpty ||
      availableOnly ||
      sort != 'newest';

  int get activeCount {
    var count = 0;
    if (city?.isNotEmpty ?? false) count++;
    if (type != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (facilityIds.isNotEmpty) count++;
    if (availableOnly) count++;
    if (sort != 'newest') count++;
    return count;
  }

  PropertyFilter copyWith({
    String? city,
    String? type,
    double? minPrice,
    double? maxPrice,
    List<String>? facilityIds,
    bool? availableOnly,
    String? sort,
    bool clearCity = false,
    bool clearType = false,
    bool clearPrice = false,
  }) {
    return PropertyFilter(
      city: clearCity ? null : (city ?? this.city),
      type: clearType ? null : (type ?? this.type),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      facilityIds: facilityIds ?? this.facilityIds,
      availableOnly: availableOnly ?? this.availableOnly,
      sort: sort ?? this.sort,
    );
  }
}

/// State layar Explore: hasil pencarian, paginasi, dan daftar fasilitas.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._service);

  final CatalogService _service;

  final List<PropertyItem> _items = [];
  ApiMeta _meta = const ApiMeta(page: 1, limit: 10, total: 0, totalPages: 0);
  final List<Facility> _facilities = [];

  String _query = '';
  PropertyFilter _filter = const PropertyFilter();
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;

  List<PropertyItem> get items => List.unmodifiable(_items);
  ApiMeta get meta => _meta;
  List<Facility> get facilities => List.unmodifiable(_facilities);
  String get query => _query;
  PropertyFilter get filter => _filter;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get hasMore => _meta.hasNextPage;
  bool get isEmpty => !_loading && _error == null && _items.isEmpty;

  Future<void> loadFacilities() async {
    if (_facilities.isNotEmpty) return;
    try {
      final result = await _service.facilities();
      _facilities
        ..clear()
        ..addAll(result);
      notifyListeners();
    } on ApiException {
      // Fasilitas bersifat pelengkap filter; kegagalannya tidak boleh
      // menggagalkan daftar properti.
    }
  }

  Future<void> search({String? query, bool showLoader = true}) async {
    if (query != null) _query = query;
    if (showLoader) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final result = await _service.searchProperties(
        q: _query,
        city: _filter.city,
        type: _filter.type,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        facilityIds: _filter.facilityIds,
        availableOnly: _filter.availableOnly,
        sort: _filter.sort,
        page: 1,
      );
      _items
        ..clear()
        ..addAll(result.items);
      _meta = result.meta;
      _error = null;
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => search(showLoader: false);

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _service.searchProperties(
        q: _query,
        city: _filter.city,
        type: _filter.type,
        minPrice: _filter.minPrice,
        maxPrice: _filter.maxPrice,
        facilityIds: _filter.facilityIds,
        availableOnly: _filter.availableOnly,
        sort: _filter.sort,
        page: _meta.page + 1,
      );
      _items.addAll(result.items);
      _meta = result.meta;
    } on ApiException catch (error) {
      _error = error.message;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void applyFilter(PropertyFilter filter) {
    _filter = filter;
    search();
  }

  void resetFilter() {
    _filter = const PropertyFilter();
    search();
  }

  /// Detail tidak disimpan di state karena tiap layar memakai FutureBuilder
  /// sendiri; provider hanya meneruskan ke service.
  Future<PropertyDetail> propertyDetail(String id) => _service.propertyDetail(id);

  Future<RoomDetail> roomDetail(String id) => _service.roomDetail(id);
}

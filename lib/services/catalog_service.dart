import '../core/api_client.dart';
import '../core/api_meta.dart';
import '../models/facility.dart';
import '../models/property.dart';
import '../models/room_detail.dart';

/// Endpoint publik: fasilitas, pencarian properti, detail properti dan kamar.
class CatalogService {
  CatalogService(this._api);

  final ApiClient _api;

  Future<List<Facility>> facilities() async {
    final payload = await _api.get('/api/facilities');
    return payload.asList.map(Facility.fromJson).toList(growable: false);
  }

  Future<({List<PropertyItem> items, ApiMeta meta})> searchProperties({
    String? q,
    String? city,
    String? type,
    double? minPrice,
    double? maxPrice,
    List<String> facilityIds = const [],
    bool availableOnly = false,
    String sort = 'newest',
    int page = 1,
    int limit = 10,
  }) async {
    final payload = await _api.get('/api/properties', query: {
      'q': q,
      'city': city,
      'type': type,
      'min_price': ?minPrice,
      'max_price': ?maxPrice,
      if (facilityIds.isNotEmpty) 'facility_ids': facilityIds.join(','),
      if (availableOnly) 'available_only': 'true',
      'sort': sort,
      'page': page,
      'limit': limit,
    });

    return (
      items: payload.asList.map(PropertyItem.fromJson).toList(growable: false),
      meta: payload.meta ??
          const ApiMeta(page: 1, limit: 10, total: 0, totalPages: 0),
    );
  }

  Future<PropertyDetail> propertyDetail(String id) async {
    final payload = await _api.get('/api/properties/$id');
    return PropertyDetail.fromJson(payload.asMap);
  }

  Future<RoomDetail> roomDetail(String id) async {
    final payload = await _api.get('/api/rooms/$id');
    return RoomDetail.fromJson(payload.asMap);
  }
}

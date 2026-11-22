import '../core/json_utils.dart';
import 'property.dart';

class UnavailableRange {
  const UnavailableRange({required this.startDate, required this.endDate});

  final String startDate;
  final String endDate;

  factory UnavailableRange.fromJson(Map<String, dynamic> json) {
    return UnavailableRange(
      startDate: asString(json['start_date']) ?? '',
      endDate: asString(json['end_date']) ?? '',
    );
  }
}

class RoomPropertySummary {
  const RoomPropertySummary({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
  });

  final String id;
  final String name;
  final String city;
  final String address;

  factory RoomPropertySummary.fromJson(Map<String, dynamic> json) {
    return RoomPropertySummary(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '-',
      city: asString(json['city']) ?? '-',
      address: asString(json['address']) ?? '-',
    );
  }
}

/// RoomDetail = RoomItem + properti induk + semua gambar + rentang terpakai.
class RoomDetail {
  const RoomDetail({
    required this.room,
    required this.property,
    required this.images,
    required this.unavailableRanges,
  });

  final RoomItem room;
  final RoomPropertySummary property;
  final List<PropertyImage> images;
  final List<UnavailableRange> unavailableRanges;

  factory RoomDetail.fromJson(Map<String, dynamic> json) {
    return RoomDetail(
      room: RoomItem.fromJson(json),
      property: RoomPropertySummary.fromJson(asMap(json['property']) ?? const {}),
      images: asMapList(json['images'])
          .map(PropertyImage.fromJson)
          .toList(growable: false),
      unavailableRanges: asMapList(json['unavailable_ranges'])
          .map(UnavailableRange.fromJson)
          .toList(growable: false),
    );
  }
}

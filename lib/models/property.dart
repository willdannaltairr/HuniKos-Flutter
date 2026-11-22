import '../core/json_utils.dart';
import 'facility.dart';

class PropertyImage {
  const PropertyImage({
    required this.id,
    required this.imageUrl,
    this.roomId,
    this.isCover = false,
  });

  final String id;
  final String imageUrl;
  final String? roomId;
  final bool isCover;

  factory PropertyImage.fromJson(Map<String, dynamic> json) {
    return PropertyImage(
      id: asString(json['id']) ?? '',
      imageUrl: asString(json['image_url']) ?? '',
      roomId: asString(json['room_id']),
      isCover: asBool(json['is_cover']),
    );
  }
}

/// Dipakai untuk daftar properti publik, daftar milik pemilik, dan daftar
/// verifikasi admin. Field tambahan hanya terisi pada endpoint masing-masing.
class PropertyItem {
  const PropertyItem({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.propertyType,
    required this.availableRooms,
    required this.totalRooms,
    this.coverImageUrl,
    this.minPrice,
    this.verificationStatus,
    this.rejectionNote,
    this.ownerId,
    this.ownerName,
    this.createdAt,
    this.description,
    this.rules,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String city;
  final String address;
  final String propertyType;
  final int availableRooms;
  final int totalRooms;
  final String? coverImageUrl;
  final double? minPrice;
  final String? verificationStatus;
  final String? rejectionNote;
  final String? ownerId;
  final String? ownerName;
  final DateTime? createdAt;

  /// Hanya diisi endpoint yang mengirim detail (mis. daftar properti pemilik),
  /// dipakai form ubah agar nilai lama tidak terhapus saat disimpan.
  final String? description;
  final String? rules;
  final double? latitude;
  final double? longitude;

  bool get isApproved => verificationStatus == 'approved';

  String get typeLabel {
    switch (propertyType) {
      case 'putra':
        return 'Putra';
      case 'putri':
        return 'Putri';
      default:
        return 'Campur';
    }
  }

  factory PropertyItem.fromJson(Map<String, dynamic> json) {
    final owner = asMap(json['owner']);
    return PropertyItem(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '-',
      city: asString(json['city']) ?? '-',
      address: asString(json['address']) ?? '-',
      propertyType: asString(json['property_type']) ?? 'campur',
      availableRooms: asInt(json['available_rooms']) ?? 0,
      totalRooms: asInt(json['total_rooms']) ?? 0,
      coverImageUrl: asString(json['cover_image_url']),
      minPrice: asDouble(json['min_price']),
      verificationStatus: asString(json['verification_status']),
      rejectionNote: asString(json['rejection_note']),
      ownerId: asString(owner?['id']),
      ownerName: asString(owner?['full_name']),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
      description: asString(json['description']),
      rules: asString(json['rules']),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
    );
  }
}

class RoomItem {
  const RoomItem({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    required this.roomType,
    required this.monthlyPrice,
    required this.maxOccupants,
    required this.bathroomType,
    required this.floorNumber,
    required this.status,
    required this.facilities,
    this.dimensions,
    this.coverImageUrl,
  });

  final String id;
  final String propertyId;
  final String roomNumber;
  final String roomType;
  final double monthlyPrice;
  final int maxOccupants;
  final String bathroomType;
  final int floorNumber;
  final String status;
  final List<Facility> facilities;
  final String? dimensions;
  final String? coverImageUrl;

  bool get isAvailable => status == 'AVAILABLE';
  bool get isBookable => status == 'AVAILABLE';

  String get bathroomLabel => bathroomType == 'dalam' ? 'KM dalam' : 'KM luar';

  factory RoomItem.fromJson(Map<String, dynamic> json) {
    return RoomItem(
      id: asString(json['id']) ?? '',
      propertyId: asString(json['property_id']) ?? '',
      roomNumber: asString(json['room_number']) ?? '-',
      roomType: asString(json['room_type']) ?? 'standard',
      monthlyPrice: asDouble(json['monthly_price']) ?? 0,
      maxOccupants: asInt(json['max_occupants']) ?? 1,
      bathroomType: asString(json['bathroom_type']) ?? 'dalam',
      floorNumber: asInt(json['floor_number']) ?? 1,
      status: asString(json['status']) ?? 'AVAILABLE',
      facilities: asMapList(json['facilities'])
          .map(Facility.fromJson)
          .toList(growable: false),
      dimensions: asString(json['dimensions']),
      coverImageUrl: asString(json['cover_image_url']),
    );
  }
}

class PropertyOwner {
  const PropertyOwner({required this.id, required this.fullName, this.phoneNumber});

  final String id;
  final String fullName;
  final String? phoneNumber;

  factory PropertyOwner.fromJson(Map<String, dynamic> json) {
    return PropertyOwner(
      id: asString(json['id']) ?? '',
      fullName: asString(json['full_name']) ?? '-',
      phoneNumber: asString(json['phone_number']),
    );
  }
}

class PropertyDetail {
  const PropertyDetail({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.propertyType,
    required this.verificationStatus,
    required this.owner,
    required this.images,
    required this.rooms,
    this.description,
    this.rules,
    this.latitude,
    this.longitude,
    this.rejectionNote,
    this.createdAt,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String propertyType;
  final String verificationStatus;
  final PropertyOwner owner;
  final List<PropertyImage> images;
  final List<RoomItem> rooms;
  final String? description;
  final String? rules;
  final double? latitude;
  final double? longitude;
  final String? rejectionNote;
  final DateTime? createdAt;

  String get typeLabel {
    switch (propertyType) {
      case 'putra':
        return 'Putra';
      case 'putri':
        return 'Putri';
      default:
        return 'Campur';
    }
  }

  factory PropertyDetail.fromJson(Map<String, dynamic> json) {
    final owner = asMap(json['owner']) ?? const <String, dynamic>{};
    return PropertyDetail(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '-',
      address: asString(json['address']) ?? '-',
      city: asString(json['city']) ?? '-',
      propertyType: asString(json['property_type']) ?? 'campur',
      verificationStatus: asString(json['verification_status']) ?? 'pending',
      owner: PropertyOwner.fromJson(owner),
      images: asMapList(json['images'])
          .map(PropertyImage.fromJson)
          .toList(growable: false),
      rooms: asMapList(json['rooms'])
          .map(RoomItem.fromJson)
          .toList(growable: false),
      description: asString(json['description']),
      rules: asString(json['rules']),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      rejectionNote: asString(json['rejection_note']),
      createdAt: DateTime.tryParse(asString(json['created_at']) ?? ''),
    );
  }
}

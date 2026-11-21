import '../core/json_utils.dart';

class Facility {
  const Facility({required this.id, required this.name});

  final String id;
  final String name;

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: asString(json['id']) ?? '',
      name: asString(json['name']) ?? '-',
    );
  }

  @override
  bool operator ==(Object other) => other is Facility && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

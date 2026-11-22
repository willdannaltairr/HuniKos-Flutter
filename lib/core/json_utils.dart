/// Pembantu parsing JSON yang tahan terhadap nilai null dan angka berbentuk
/// teks, karena backend mengirim angka sebagai number tetapi beberapa kolom
/// opsional bisa null.
library;

double? asDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? asInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? asString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

Map<String, dynamic>? asMap(Object? value) {
  return value is Map<String, dynamic> ? value : null;
}

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

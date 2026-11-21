import 'package:intl/intl.dart';

/// Format uang, tanggal, dan waktu yang dipakai di seluruh layar.
class Formatters {
  const Formatters._();

  static final NumberFormat _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String rupiah(num? value) {
    if (value == null) return '-';
    return _rupiah.format(value);
  }

  /// Tanggal dari API berupa teks `YYYY-MM-DD` dan tidak boleh diubah ke UTC,
  /// jadi diurai sebagai tanggal lokal tanpa konversi zona waktu.
  static DateTime? parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static DateTime? parseDateTime(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  static String date(String? value) {
    final parsed = parseDate(value);
    if (parsed == null) return '-';
    return DateFormat('d MMMM yyyy', 'id_ID').format(parsed);
  }

  static String shortDate(String? value) {
    final parsed = parseDate(value);
    if (parsed == null) return '-';
    return DateFormat('d MMM yyyy', 'id_ID').format(parsed);
  }

  static String dateTime(String? value) {
    final parsed = parseDateTime(value);
    if (parsed == null) return '-';
    return DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(parsed);
  }

  static String dateRange(String? start, String? end) {
    return '${shortDate(start)} – ${shortDate(end)}';
  }

  /// Dipakai form booking: tanggal mulai + durasi bulan, dihitung di server.
  static String isoDate(DateTime value) {
    return DateFormat('yyyy-MM-dd').format(value);
  }

  static String todayInJakarta() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Sisa waktu pembayaran dalam bentuk singkat, misal "23 jam 10 menit".
  static String countdown(DateTime? expiresAt) {
    if (expiresAt == null) return '-';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Sudah kedaluwarsa';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours >= 1) return '$hours jam $minutes menit';
    return '$minutes menit';
  }
}

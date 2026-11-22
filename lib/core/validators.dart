/// Aturan validasi form, cerminan kontrak bagian 7. Server tetap sumber akhir;
/// validator ini hanya mencegah request yang jelas akan ditolak.
class Validators {
  const Validators._();

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama lengkap wajib diisi';
    if (text.length < 2) return 'Nama lengkap minimal 2 karakter';
    if (text.length > 100) return 'Nama lengkap maksimal 100 karakter';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    if (text.length > 150) return 'Email maksimal 150 karakter';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password wajib diisi';
    if (text.length < 8) return 'Password minimal 8 karakter';
    if (text.length > 72) return 'Password maksimal 72 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) {
      return 'Password minimal mengandung 1 huruf';
    }
    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return 'Password minimal mengandung 1 angka';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Konfirmasi password wajib diisi';
    if (value != original) return 'Konfirmasi password tidak sama';
    return null;
  }

  static String? phoneNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[0-9+]{8,20}$').hasMatch(text)) {
      return 'Hanya angka dan tanda plus, 8-20 karakter';
    }
    return null;
  }

  static String? requiredText(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? textLength(
    String? value,
    String label, {
    int? min,
    required int max,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi';
    if (min != null && text.length < min) {
      return '$label minimal $min karakter';
    }
    if (text.length > max) return '$label maksimal $max karakter';
    return null;
  }

  static String? optionalTextLength(
    String? value,
    String label, {
    required int max,
  }) {
    final text = value?.trim() ?? '';
    if (text.length > max) return '$label maksimal $max karakter';
    return null;
  }

  static String? price(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return 'Harga wajib diisi';
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) return 'Harga harus lebih dari 0';
    if (amount > 100000000) return 'Harga maksimal 100.000.000';
    return null;
  }

  static String? numberRange(
    String? value,
    String label, {
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return '$label wajib diisi';
    if (parsed < min) return '$label minimal $min';
    if (parsed > max) return '$label maksimal $max';
    return null;
  }

  /// Latitude dan longitude harus diisi bersamaan.
  static String? coordinate(String? value, String label, {required bool isLatitude}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    final limit = isLatitude ? 90.0 : 180.0;
    if (parsed == null) return '$label harus berupa angka';
    if (parsed < -limit || parsed > limit) {
      return '$label harus di antara ${-limit.toInt()} dan ${limit.toInt()}';
    }
    return null;
  }
}

import 'i18n.dart';

/// Aturan validasi form, cerminan kontrak bagian 7. Server tetap sumber akhir;
/// validator ini hanya mencegah request yang jelas akan ditolak.
/// Pesan memakai I18n supaya mengikuti bahasa yang dipilih pengguna.
class Validators {
  const Validators._();

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return I18n.t('val.nameRequired');
    if (text.length < 2) return I18n.t('val.nameMin');
    if (text.length > 100) return I18n.t('val.nameMax');
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return I18n.t('val.emailRequired');
    if (text.length > 150) return I18n.t('val.emailMax');
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(text)) return I18n.t('val.emailInvalid');
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return I18n.t('val.passwordRequired');
    if (text.length < 8) return I18n.t('val.passwordMin');
    if (text.length > 72) return I18n.t('val.passwordMax');
    if (!RegExp(r'[A-Za-z]').hasMatch(text)) return I18n.t('val.passwordLetter');
    if (!RegExp(r'[0-9]').hasMatch(text)) return I18n.t('val.passwordNumber');
    return null;
  }

  static String? passwordConfirmation(String? value, String original) {
    if ((value ?? '').isEmpty) return I18n.t('val.confirmRequired');
    if (value != original) return I18n.t('val.confirmMismatch');
    return null;
  }

  static String? phoneNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^[0-9+]{8,20}$').hasMatch(text)) return I18n.t('val.phoneChars');
    return null;
  }

  /// Nomor seluler Indonesia untuk pendaftaran: wajib diisi, diawali +62,
  /// lalu angka 8 dan 8-11 angka berikutnya (contoh +6281234567890).
  static String? phoneNumberRequired(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (text.isEmpty || text == '+62') return I18n.t('val.phoneRequired');
    if (!text.startsWith('+62')) return I18n.t('val.phonePrefix');
    if (!RegExp(r'^\+628\d{8,11}$').hasMatch(text)) return I18n.t('val.phoneInvalid');
    return null;
  }

  static String? requiredText(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return I18n.t('val.required', {'label': label});
    }
    return null;
  }

  static String? textLength(
    String? value,
    String label, {
    int? min,
    required int max,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return I18n.t('val.required', {'label': label});
    if (min != null && text.length < min) {
      return I18n.t('val.min', {'label': label, 'min': '$min'});
    }
    if (text.length > max) {
      return I18n.t('val.max', {'label': label, 'max': '$max'});
    }
    return null;
  }

  static String? optionalTextLength(
    String? value,
    String label, {
    required int max,
  }) {
    final text = value?.trim() ?? '';
    if (text.length > max) {
      return I18n.t('val.max', {'label': label, 'max': '$max'});
    }
    return null;
  }

  static String? price(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return I18n.t('val.priceRequired');
    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) return I18n.t('val.pricePositive');
    if (amount > 100000000) return I18n.t('val.priceMax');
    return null;
  }

  static String? numberRange(
    String? value,
    String label, {
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return I18n.t('val.required', {'label': label});
    if (parsed < min) {
      return I18n.t('val.minSimple', {'label': label, 'min': '$min'});
    }
    if (parsed > max) {
      return I18n.t('val.maxSimple', {'label': label, 'max': '$max'});
    }
    return null;
  }

  /// Latitude dan longitude harus diisi bersamaan.
  static String? coordinate(String? value, String label, {required bool isLatitude}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    final limit = isLatitude ? 90.0 : 180.0;
    if (parsed == null) {
      return I18n.t('val.coordinateNumber', {'label': label});
    }
    if (parsed < -limit || parsed > limit) {
      return I18n.t('val.coordinateRange', {
        'label': label,
        'min': '${-limit.toInt()}',
        'max': '${limit.toInt()}',
      });
    }
    return null;
  }
}

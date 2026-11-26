import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bahasa yang dipakai antarmuka. Dua saja sesuai permintaan.
enum AppLanguage { id, en }

/// Pengaturan tampilan yang bisa diganti pengguna: mode gelap/terang dan
/// bahasa. Disimpan di secure storage supaya bertahan setelah aplikasi
/// ditutup.
class AppSettings extends ChangeNotifier {
  AppSettings({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _themeKey = 'hunikos_theme_mode';
  static const _langKey = 'hunikos_language';

  final FlutterSecureStorage _storage;

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.id;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Dibaca sekali saat aplikasi dibuka. Gagal membaca dikembalikan ke
  /// bawaan (terang + Indonesia) alih-alih membuat aplikasi tidak jalan.
  Future<void> load() async {
    try {
      final theme = await _storage.read(key: _themeKey);
      final lang = await _storage.read(key: _langKey);
      if (theme == 'dark') _themeMode = ThemeMode.dark;
      if (theme == 'light') _themeMode = ThemeMode.light;
      if (lang == 'en') _language = AppLanguage.en;
      if (lang == 'id') _language = AppLanguage.id;
    } catch (_) {
      // Penyimpanan tidak tersedia: pakai bawaan.
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _storage.write(key: _themeKey, value: mode == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {
      // Tetap berlaku selama aplikasi terbuka walau gagal menyimpan.
    }
  }

  Future<void> toggleTheme() =>
      setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    try {
      await _storage.write(key: _langKey, value: language == AppLanguage.en ? 'en' : 'id');
    } catch (_) {
      // Sama seperti mode tema.
    }
  }

  Future<void> toggleLanguage() => setLanguage(
        _language == AppLanguage.id ? AppLanguage.en : AppLanguage.id,
      );
}

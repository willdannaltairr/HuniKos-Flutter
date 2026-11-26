import 'package:flutter_test/flutter_test.dart';
import 'package:hunikos/core/app_settings.dart';
import 'package:hunikos/core/i18n.dart';

void main() {
  tearDown(() => I18n.use(AppLanguage.id));

  test('bahasa Indonesia dipakai sebagai bawaan', () {
    I18n.use(AppLanguage.id);
    expect(I18n.t('auth.tabLogin'), 'Masuk');
  });

  test('pergantian bahasa mengubah teks yang sama', () {
    I18n.use(AppLanguage.en);
    expect(I18n.t('auth.tabLogin'), 'Sign in');
    expect(I18n.t('auth.tabRegister'), 'Sign up');
    expect(I18n.t('profile.darkMode'), 'Dark mode');
  });

  test('parameter disubstitusi ke dalam terjemahan', () {
    I18n.use(AppLanguage.id);
    expect(
      I18n.t('auth.socialUnavailable', {'provider': 'Google'}),
      'Masuk dengan Google belum tersedia. Gunakan email dan password.',
    );

    I18n.use(AppLanguage.en);
    expect(
      I18n.t('auth.socialUnavailable', {'provider': 'Apple'}),
      'Sign in with Apple is not available. Use email and password.',
    );
  });

  test('kunci yang belum diterjemahkan jatuh ke kuncinya sendiri', () {
    I18n.use(AppLanguage.en);
    expect(I18n.t('kunci.belum.ada'), 'kunci.belum.ada');
  });
}

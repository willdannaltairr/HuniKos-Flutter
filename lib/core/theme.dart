import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Satu set warna untuk satu mode tampilan.
class _Palette {
  const _Palette({
    required this.ink,
    required this.inkSoft,
    required this.paper,
    required this.paperSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.blueTint,
    required this.danger,
    required this.dangerText,
    required this.success,
    required this.successText,
    required this.warning,
    required this.warningText,
    required this.neutralText,
    required this.gold,
    required this.goldSoft,
    required this.goldDeep,
    required this.rose,
    required this.buttonBg,
    required this.onButton,
    required this.navBar,
  });

  final Color ink;
  final Color inkSoft;
  final Color paper;
  final Color paperSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color blueTint;
  final Color danger;
  final Color dangerText;
  final Color success;
  final Color successText;
  final Color warning;
  final Color warningText;
  final Color neutralText;
  final Color gold;
  final Color goldSoft;
  final Color goldDeep;
  final Color rose;
  final Color buttonBg;
  final Color onButton;
  final Color navBar;
}

const _lightPalette = _Palette(
  ink: Color(0xFF222222),
  inkSoft: Color(0xFF484848),
  paper: Color(0xFFFFFFFF),
  paperSoft: Color(0xFFF7F7F7),
  textPrimary: Color(0xFF222222),
  textSecondary: Color(0xFF717171),
  border: Color(0xFFDDDDDD),
  background: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  surfaceHigh: Color(0xFFF7F7F7),
  blueTint: Color(0xFFF7F7F7),
  danger: Color(0xFFC13515),
  dangerText: Color(0xFFB91C1C),
  success: Color(0xFF008A05),
  successText: Color(0xFF15803D),
  warning: Color(0xFFB45309),
  warningText: Color(0xFFB45309),
  neutralText: Color(0xFF717171),
  gold: Color(0xFF222222),
  goldSoft: Color(0xFFF2F2F2),
  goldDeep: Color(0xFF222222),
  rose: Color(0xFFFF385C),
  buttonBg: Color(0xFF222222),
  onButton: Colors.white,
  navBar: Color(0xFF222222),
);

const _darkPalette = _Palette(
  ink: Color(0xFFF5F5F5),
  inkSoft: Color(0xFFC9C9C9),
  paper: Color(0xFF181818),
  paperSoft: Color(0xFF242424),
  textPrimary: Color(0xFFF5F5F5),
  textSecondary: Color(0xFFA8A8A8),
  border: Color(0xFF3A3A3A),
  background: Color(0xFF101010),
  surface: Color(0xFF181818),
  surfaceHigh: Color(0xFF242424),
  blueTint: Color(0xFF242424),
  danger: Color(0xFFFF6B5B),
  dangerText: Color(0xFFFF8A7A),
  success: Color(0xFF4ADE80),
  successText: Color(0xFF6EE7A0),
  warning: Color(0xFFFBBF24),
  warningText: Color(0xFFFCD34D),
  neutralText: Color(0xFFA8A8A8),
  gold: Color(0xFFF5F5F5),
  goldSoft: Color(0xFF2C2C2C),
  goldDeep: Color(0xFFF5F5F5),
  rose: Color(0xFFFF5A7A),
  buttonBg: Color(0xFFF5F5F5),
  onButton: Color(0xFF111111),
  navBar: Color(0xFF1D1D1F),
);

/// Warna aplikasi. Nilainya diambil dari palet terang atau gelap sesuai mode
/// yang sedang aktif, sehingga satu nama token dipakai semua layar.
class AppColors {
  const AppColors._();

  static bool _dark = false;

  static void useDark(bool value) => _dark = value;
  static bool get isDark => _dark;

  static _Palette get _p => _dark ? _darkPalette : _lightPalette;

  static Color get ink => _p.ink;
  static Color get inkSoft => _p.inkSoft;
  static Color get paper => _p.paper;
  static Color get paperSoft => _p.paperSoft;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get border => _p.border;
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceHigh => _p.surfaceHigh;
  static Color get blueTint => _p.blueTint;
  static Color get danger => _p.danger;
  static Color get dangerText => _p.dangerText;
  static Color get success => _p.success;
  static Color get successText => _p.successText;
  static Color get warning => _p.warning;
  static Color get warningText => _p.warningText;
  static Color get neutralText => _p.neutralText;
  static Color get gold => _p.gold;
  static Color get goldSoft => _p.goldSoft;
  static Color get goldDeep => _p.goldDeep;
  static Color get rose => _p.rose;
  static Color get buttonBg => _p.buttonBg;
  static Color get onButton => _p.onButton;
  static Color get navBar => _p.navBar;

  // Nama lama tetap ada supaya layar yang sudah ada tidak perlu diubah.
  static Color get navy => ink;
  static Color get navySoft => inkSoft;
  static Color get steel => paperSoft;
  static Color get steelDeep => paper;
  static Color get cream => paperSoft;
  static Color get ivory => paper;
  static Color get primary => ink;
  static Color get shim => paperSoft;
  static Color get glow => paper;
}

class AppFonts {
  const AppFonts._();

  static const display = 'Outfit';
  static const body = 'DM Sans';

  static TextStyle title(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: height ?? 1.2,
      letterSpacing: -0.4,
    );
  }

  static TextStyle label(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: -0.1,
    );
  }
}

class AppTheme {
  const AppTheme._();

  /// Mode menentukan palet mana yang dipakai seluruh widget.
  static ThemeData build(ThemeMode mode) {
    final dark = mode == ThemeMode.dark;
    // Widget membaca warna lewat AppColors, jadi palet harus dipilih di sini
    // sebelum ThemeData disusun.
    AppColors.useDark(dark);
    final brightness = dark ? Brightness.dark : Brightness.light;
    final base = GoogleFonts.dmSansTextTheme(ThemeData(brightness: brightness).textTheme);

    final textTheme = base.copyWith(
      displayLarge: AppFonts.title(44),
      displayMedium: AppFonts.title(38),
      displaySmall: AppFonts.title(32),
      headlineLarge: AppFonts.title(29),
      headlineMedium: AppFonts.title(25, weight: FontWeight.w600),
      headlineSmall: AppFonts.title(22),
      titleLarge: AppFonts.title(19),
      bodyLarge: AppFonts.label(15),
      bodyMedium: AppFonts.label(13.5),
      bodySmall: AppFonts.label(12, color: AppColors.textSecondary),
      labelLarge: AppFonts.label(14, weight: FontWeight.w600),
      labelMedium: AppFonts.label(12, weight: FontWeight.w500),
      labelSmall: AppFonts.label(11, weight: FontWeight.w500, color: AppColors.textSecondary),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: AppColors.onButton,
      secondary: AppColors.paperSoft,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.title(21),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppFonts.label(13.5, color: AppColors.textSecondary),
        labelStyle: AppFonts.label(13.5, color: AppColors.textSecondary),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.buttonBg,
          foregroundColor: AppColors.onButton,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: AppColors.textPrimary, width: 1.2),
          shape: const StadiumBorder(),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: AppFonts.label(14, weight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.buttonBg,
        side: BorderSide(color: AppColors.border),
        labelStyle: AppFonts.label(13, weight: FontWeight.w500),
        secondaryLabelStyle: AppFonts.label(13, weight: FontWeight.w600, color: AppColors.onButton),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.white.withValues(alpha: 0.16),
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppFonts.label(
            11,
            weight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.62),
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white.withValues(alpha: 0.62),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        backgroundColor: AppColors.navBar,
        contentTextStyle: AppFonts.label(13.5, color: Colors.white),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppFonts.title(20),
        contentTextStyle: AppFonts.label(14, color: AppColors.textSecondary),
      ),
      listTileTheme: ListTileThemeData(iconColor: AppColors.textPrimary),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    );
  }

  static Widget backdrop({required Widget child}) {
    return ColoredBox(color: AppColors.background, child: child);
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

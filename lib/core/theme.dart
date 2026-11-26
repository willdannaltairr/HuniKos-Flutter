import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet HuniKos bergaya Airbnb: kanvas putih, teks hampir hitam, dan abu
/// lembut untuk keterangan. Warna aksen hanya dipakai untuk status dan
/// penanda kecil supaya halaman terasa tenang.
class AppColors {
  const AppColors._();

  // Nama lama dipertahankan agar layar yang sudah ada tetap memakai token
  // yang sama; nilainya sekarang mengikuti tema terang.
  static const ink = Color(0xFF222222);
  static const inkSoft = Color(0xFF484848);
  static const paper = Color(0xFFFFFFFF);
  static const paperSoft = Color(0xFFF7F7F7);

  static const navy = ink;
  static const navySoft = inkSoft;
  static const steel = paperSoft;
  static const steelDeep = paper;
  static const cream = paperSoft;
  static const ivory = paper;

  /// Aksen utama: hitam pekat seperti tombol pada aplikasi perjalanan.
  static const gold = ink;
  static const goldSoft = Color(0xFFF2F2F2);
  static const goldDeep = ink;

  // Peran semantik.
  static const primary = ink;
  static const background = paper;
  static const surface = paper;
  static const surfaceHigh = paperSoft;
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF717171);
  static const blueTint = paperSoft;
  static const border = Color(0xFFDDDDDD);
  static const danger = Color(0xFFC13515);

  static const success = Color(0xFF008A05);
  static const successText = Color(0xFF008A05);
  static const warning = Color(0xFFB45309);
  static const warningText = Color(0xFFB45309);
  static const dangerText = Color(0xFFC13515);
  static const neutralText = Color(0xFF717171);

  /// Warna penanda favorit, satu-satunya aksen merah lembut di aplikasi.
  static const rose = Color(0xFFFF385C);

  static const shim = paperSoft;
  static const glow = paper;
}

class AppFonts {
  const AppFonts._();

  /// Sans geometris dengan ujung lembut untuk judul.
  static const display = 'Outfit';

  /// Sans netral yang tenang untuk teks isi dan form.
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

  static ThemeData build() {
    final base = GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme);

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
      seedColor: AppColors.ink,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.paperSoft,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
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
        focusedBorder: _inputBorder(AppColors.ink, width: 1.6),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: AppColors.paper,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.ink, width: 1.2),
          shape: const StadiumBorder(),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppFonts.label(14, weight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.ink,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppFonts.label(13, weight: FontWeight.w500),
        secondaryLabelStyle: AppFonts.label(13, weight: FontWeight.w600, color: Colors.white),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.ink,
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
        backgroundColor: AppColors.ink,
        contentTextStyle: AppFonts.label(13.5, color: Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.ink),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
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
      listTileTheme: const ListTileThemeData(iconColor: AppColors.ink),
      iconTheme: const IconThemeData(color: AppColors.ink),
    );
  }

  /// Latar halaman: kanvas putih polos, tanpa gradasi.
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

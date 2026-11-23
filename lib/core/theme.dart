import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet HuniKos: malam biru-baja dengan aksen krem dan emas.
/// Latar gelap dibuat berlapis (steel → steelDeep) supaya terasa seperti
/// ruang yang disinari lampu hangat, bukan blok warna datar.
class AppColors {
  const AppColors._();

  static const steel = Color(0xFF2A3E54);
  static const steelDeep = Color(0xFF16222F);
  static const navy = Color(0xFF14213D);
  static const navySoft = Color(0xFF1D3049);

  static const cream = Color(0xFFF4EDE0);
  static const ivory = Color(0xFFFFFBF3);
  static const gold = Color(0xFFE4C27A);
  static const goldSoft = Color(0xFFF2E8CF);
  static const goldDeep = Color(0xFFB99248);

  // Peran semantik: dipakai layar, jadi namanya menjelaskan fungsinya.
  static const primary = gold;
  static const background = Color(0xFF1B2A3A);
  static const surface = Color(0xFF24374B);
  static const surfaceHigh = Color(0xFF2C4159);
  static const textPrimary = Color(0xFFF4EDE0);
  static const textSecondary = Color(0xFFA7B7C6);
  static const blueTint = Color(0xFF2C4159);
  static const border = Color(0xFF354A60);
  static const danger = Color(0xFFE0796E);

  static const success = Color(0xFF7CC79A);
  static const successText = Color(0xFF8FD9AE);
  static const warning = Color(0xFFE4C27A);
  static const warningText = Color(0xFFE4C27A);
  static const dangerText = Color(0xFFF0A7A0);
  static const neutralText = Color(0xFFA7B7C6);

  /// Latar kartu yang sedikit lebih terang dari halaman.
  static const shim = Color(0x14FFFFFF);

  /// Pendaran cahaya di bagian atas layar, seperti sorot lampu.
  static const glow = Color(0xFF6E8CAB);
}

class AppFonts {
  const AppFonts._();

  /// Sans geometris dengan ujung lembut untuk judul.
  static const display = 'Outfit';

  /// Sans netral yang tenang untuk teks isi dan form.
  static const body = 'DM Sans';

  static TextStyle title(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: height ?? 1.22,
      letterSpacing: -0.5,
    );
  }

  static TextStyle label(double size, {FontWeight weight = FontWeight.w400, Color? color}) {
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
    final base = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme);

    final textTheme = base.copyWith(
      displayLarge: AppFonts.title(44, weight: FontWeight.w600),
      displayMedium: AppFonts.title(38, weight: FontWeight.w600),
      displaySmall: AppFonts.title(32, weight: FontWeight.w600),
      headlineLarge: AppFonts.title(29, weight: FontWeight.w600),
      headlineMedium: AppFonts.title(25, weight: FontWeight.w500),
      headlineSmall: AppFonts.title(22, weight: FontWeight.w500),
      titleLarge: AppFonts.title(19, weight: FontWeight.w500),
      bodyLarge: AppFonts.label(15, color: AppColors.textPrimary),
      bodyMedium: AppFonts.label(13.5, color: AppColors.textPrimary),
      bodySmall: AppFonts.label(12, color: AppColors.textSecondary),
      labelLarge: AppFonts.label(14, weight: FontWeight.w600),
      labelMedium: AppFonts.label(12, weight: FontWeight.w500),
      labelSmall: AppFonts.label(11, weight: FontWeight.w500, color: AppColors.textSecondary),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppColors.gold,
      onPrimary: AppColors.navy,
      secondary: AppColors.cream,
      onSecondary: AppColors.navy,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.title(21, weight: FontWeight.w500),
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
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppFonts.label(13.5, color: AppColors.textSecondary),
        labelStyle: AppFonts.label(13.5, color: AppColors.textSecondary),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.gold, width: 1.5),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cream,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppFonts.label(14, weight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.gold,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppFonts.label(13, weight: FontWeight.w500),
        secondaryLabelStyle: AppFonts.label(13, weight: FontWeight.w600, color: AppColors.navy),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.steelDeep.withValues(alpha: 0.94),
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.gold.withValues(alpha: 0.22),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppFonts.label(
            11.5,
            weight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppFonts.label(13.5, color: AppColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: AppFonts.title(20, weight: FontWeight.w500),
        contentTextStyle: AppFonts.label(14, color: AppColors.textSecondary),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.gold),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }

  /// Latar halaman: gradasi malam biru dengan pendaran lembut di tengah atas.
  static Widget backdrop({required Widget child}) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.steel, AppColors.steelDeep],
          stops: [0.0, 0.75],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -220,
            left: -120,
            right: -120,
            child: IgnorePointer(
              child: Container(
                height: 520,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0x556E8CAB), Color(0x002A3E54)],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

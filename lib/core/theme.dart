import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet HuniKos: navy tua, krem hangat, dan emas sebagai aksen.
/// Varian teks emas lebih gelap supaya kontrasnya cukup di atas krem.
class AppColors {
  const AppColors._();

  static const navy = Color(0xFF14213D);
  static const navySoft = Color(0xFF22314F);
  static const cream = Color(0xFFF4EDE0);
  static const ivory = Color(0xFFFFFBF3);
  static const gold = Color(0xFFC8A951);
  static const goldSoft = Color(0xFFF2E8CF);
  static const goldDeep = Color(0xFF8A6A22);

  // Nama lama dipertahankan agar layar lain tidak perlu diubah sekaligus.
  static const primary = navy;
  static const background = cream;
  static const surface = ivory;
  static const textPrimary = navy;
  static const textSecondary = Color(0xFF5C6674);
  static const blueTint = Color(0xFFE8E5DA);
  static const border = Color(0xFFE3DAC9);
  static const danger = Color(0xFFB3261E);

  static const success = Color(0xFF2F7D4F);
  static const successText = Color(0xFF1F6B41);
  static const warning = Color(0xFFB7791F);
  static const warningText = Color(0xFF8A5A12);
  static const dangerText = Color(0xFF9B1C1C);
  static const neutralText = Color(0xFF5C6674);

  /// Warna tipis untuk latar kartu di atas krem.
  static const shim = Color(0x14000000);
}

class AppFonts {
  const AppFonts._();

  /// Serif untuk judul besar agar terasa seperti majalah perjalanan.
  static const display = 'Fraunces';

  /// Sans geometris untuk isi dan tombol: lembut dibaca di ukuran kecil.
  static const body = 'Manrope';

  static TextStyle title(double size, {FontWeight weight = FontWeight.w600, Color? color}) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: 1.2,
      letterSpacing: -0.4,
    );
  }

  static TextStyle label(double size, {FontWeight weight = FontWeight.w600, Color? color}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData build() {
    final body = GoogleFonts.manropeTextTheme(ThemeData.light().textTheme);

    // Judul memakai serif; isi tetap sans agar form dan tabel mudah dibaca.
    final textTheme = body.copyWith(
      displayLarge: AppFonts.title(42, weight: FontWeight.w700),
      displayMedium: AppFonts.title(36, weight: FontWeight.w700),
      displaySmall: AppFonts.title(30, weight: FontWeight.w700),
      headlineLarge: AppFonts.title(28, weight: FontWeight.w700),
      headlineMedium: AppFonts.title(24, weight: FontWeight.w700),
      headlineSmall: AppFonts.title(21, weight: FontWeight.w600),
      titleLarge: AppFonts.title(19, weight: FontWeight.w600),
      bodyLarge: AppFonts.label(15, weight: FontWeight.w500, color: AppColors.textPrimary),
      bodyMedium: AppFonts.label(13.5, weight: FontWeight.w500, color: AppColors.textPrimary),
      bodySmall: AppFonts.label(12, weight: FontWeight.w500, color: AppColors.textSecondary),
      labelLarge: AppFonts.label(14, weight: FontWeight.w700),
      labelMedium: AppFonts.label(12, weight: FontWeight.w600),
      labelSmall: AppFonts.label(11, weight: FontWeight.w600, color: AppColors.textSecondary),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.navy,
      onPrimary: AppColors.ivory,
      secondary: AppColors.gold,
      onSecondary: AppColors.navy,
      surface: AppColors.ivory,
      onSurface: AppColors.textPrimary,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppFonts.title(20, weight: FontWeight.w600),
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
        hintStyle: AppFonts.label(13.5, weight: FontWeight.w500, color: AppColors.textSecondary),
        labelStyle: AppFonts.label(13.5, weight: FontWeight.w500, color: AppColors.textSecondary),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.navy, width: 1.6),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.ivory,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.navy),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: AppFonts.label(14.5, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy,
          textStyle: AppFonts.label(14, weight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.navy,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppFonts.label(13, weight: FontWeight.w600),
        secondaryLabelStyle: AppFonts.label(13, weight: FontWeight.w600, color: AppColors.ivory),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.goldSoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppFonts.label(
            11.5,
            weight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: AppColors.navy,
        contentTextStyle: AppFonts.label(13.5, weight: FontWeight.w500, color: AppColors.ivory),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.navy),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.ivory,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: AppFonts.title(19, weight: FontWeight.w600),
        contentTextStyle: AppFonts.label(14, weight: FontWeight.w500, color: AppColors.textSecondary),
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.navy),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

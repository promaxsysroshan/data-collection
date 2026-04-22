import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const Color primary        = Color(0xFF1A1A1A);
  static const Color primaryDark    = Color(0xFF000000);
  static const Color primaryLight   = Color(0xFF444444);
  static const Color secondary      = Color(0xFF555555);
  static const Color accent         = Color(0xFF1A1A1A);
  static const Color success        = Color(0xFF2D7D46);
  static const Color warning        = Color(0xFF92620A);
  static const Color error          = Color(0xFFB91C1C);
  static const Color info           = Color(0xFF1D4ED8);
  static const Color background     = Color(0xFFF8F7F5);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F1EF);
  static const Color surfaceElevated= Color(0xFFEBEAE8);
  static const Color cardBg         = Color(0xFFFFFFFF);
  static const Color textPrimary    = Color(0xFF1A1A1A);
  static const Color textSecondary  = Color(0xFF555555);
  static const Color textMuted      = Color(0xFF888888);
  static const Color border         = Color(0xFFE4E4E0);
  static const Color borderLight    = Color(0xFFEEEEEB);

  static const List<Color> primaryGradient = [Color(0xFF1A1A1A), Color(0xFF444444)];
  static const List<Color> adminGradient   = [Color(0xFF1A1A1A), Color(0xFF333333)];
  static const List<Color> level1Gradient  = [Color(0xFF1D4ED8), Color(0xFF2563EB)];
  static const List<Color> walletGradient  = [Color(0xFF1A1A1A), Color(0xFF333333)];
  static const List<Color> successGradient = [Color(0xFF2D7D46), Color(0xFF16A34A)];
  static const List<Color> warningGradient = [Color(0xFF92620A), Color(0xFFB45309)];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Georgia',
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: 'Georgia',
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textSecondary),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Georgia'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: const BorderSide(color: AppColors.border),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
        dividerColor: AppColors.border,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

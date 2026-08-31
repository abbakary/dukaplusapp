import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light({String? businessType}) {
    final primary = AppColors.forBusiness(businessType);
    final cs = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      error: AppColors.danger,
    );

    final base = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.copyWith(
        displayLarge:  base.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        displayMedium: base.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineLarge: base.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 24),
        headlineMedium: base.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        headlineSmall: base.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleLarge:  base.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        titleMedium: base.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
        titleSmall:  base.titleSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 13),
        bodyLarge:   base.bodyLarge?.copyWith(color: AppColors.textPrimary, fontSize: 15),
        bodyMedium:  base.bodyMedium?.copyWith(color: AppColors.textSecondary, fontSize: 13),
        bodySmall:   base.bodySmall?.copyWith(color: AppColors.textHint, fontSize: 12),
        labelLarge:  base.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
        labelSmall:  base.labelSmall?.copyWith(fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 13),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider, thickness: 1, space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        elevation: 8,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

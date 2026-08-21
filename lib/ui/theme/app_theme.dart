import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F172A);      // Slate 900
  static const primaryDark = Color(0xFF020617);  // Slate 950
  static const accent = Color(0xFF2563EB);       // Blue 600
  static const accentLight = Color(0xFF3B82F6);  // Blue 500
  static const surface = Color(0xFFF8FAFC);     // Slate 50
  static const cardBg = Colors.white;
  static const border = Color(0xFFE2E8F0);      // Slate 200
  static const textMain = Color(0xFF1E293B);     // Slate 800
  static const textMuted = Color(0xFF64748B);    // Slate 500
  
  // Espectros
  static const spectrumDesign = Color(0xFF2563EB);   // Azul
  static const spectrumElastic = Color(0xFFEA580C);  // Naranja
  static const spectrumEpu = Color(0xFF9333EA);      // Morado
  static const spectrumNtc2004 = Color(0xFF059669);  // Verde esmeralda
  static const spectrumNtc2004Ap = Color(0xFFDC2626); // Rojo
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        secondary: const Color(0xFF0D9488),
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF0F172A); // Slate 900
  static const primaryDark = Color(0xFF020617); // Slate 950
  static const accent = Color(0xFF2563EB); // Blue 600
  static const accentLight = Color(0xFF3B82F6); // Blue 500
  static const accentSoft = Color(0xFFDBEAFE); // Blue 100
  static const surface = Color(0xFFF8FAFC); // Slate 50
  static const cardBg = Colors.white;
  static const border = Color(0xFFE2E8F0); // Slate 200
  static const borderStrong = Color(0xFFCBD5E1); // Slate 300
  static const textMain = Color(0xFF1E293B); // Slate 800
  static const textMuted = Color(0xFF64748B); // Slate 500
  static const textFaint = Color(0xFF94A3B8); // Slate 400

  // Estados
  static const success = Color(0xFF059669); // Emerald 600
  static const warning = Color(0xFFB45309); // Amber 700
  static const warningBg = Color(0xFFFFFBEB); // Amber 50
  static const warningBorder = Color(0xFFFDE68A); // Amber 200
  static const infoBg = Color(0xFFEFF6FF); // Blue 50
  static const chipBg = Color(0xFFF1F5F9); // Slate 100

  // Espectros
  static const spectrumDesign = Color(0xFF2563EB); // Azul
  static const spectrumElastic = Color(0xFFEA580C); // Naranja
  static const spectrumEpu = Color(0xFF9333EA); // Morado
  static const spectrumNtc2004 = Color(0xFF059669); // Verde esmeralda
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
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 2,
        shadowColor: AppColors.primary.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: const BorderSide(color: AppColors.borderStrong),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.all(
                AppColors.accent.withValues(alpha: 0.06),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.6),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.borderStrong,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(0),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.chipBg,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textMuted,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.textMuted,
          ),
          textStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 38)),
          visualDensity: VisualDensity.compact,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        elevation: 10,
        shadowColor: AppColors.primary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        position: PopupMenuPosition.under,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        preferBelow: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentLight,
        linearTrackColor: Colors.white24,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
      ),
    );
  }
}

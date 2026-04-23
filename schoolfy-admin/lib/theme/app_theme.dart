import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Dark Palette (matches login screen) ──────────────────────────────
  static const Color bgColor      = Color(0xFF080B14);
  static const Color surfaceColor = Color(0xFF0D1526);
  static const Color cardColor    = Color(0xFF111B2E);
  static const Color borderColor  = Color(0xFF1E3A5F);
  static const Color dividerColor = Color(0xFF1A2D4A);

  // ── Brand Colors ─────────────────────────────────────────────────────────
  static const Color primaryColor   = Color(0xFF3B82F6); // blue-500
  static const Color primaryVariant = Color(0xFF1D4ED8); // blue-700
  static const Color secondaryColor = Color(0xFF06B6D4); // cyan-500
  static const Color accentColor    = Color(0xFF6366F1); // indigo-500

  // ── Semantic Colors ───────────────────────────────────────────────────────
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor   = Color(0xFFEF4444);
  static const Color infoColor    = Color(0xFF3B82F6);

  // ── Grade Colors ─────────────────────────────────────────────────────────
  static const Color gradeColor1 = Color(0xFFEF4444);
  static const Color gradeColor2 = Color(0xFF3B82F6);
  static const Color gradeColor3 = Color(0xFF22C55E);
  static const Color gradeColor4 = Color(0xFFF59E0B);
  static const Color gradeColor5 = Color(0xFF8B5CF6);
  static const Color gradeColor6 = Color(0xFF06B6D4);

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF64748B);

  // ── Light Text (for light mode) ───────────────────────────────────────────
  static const Color lightTextPrimary   = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted     = Color(0xFF94A3B8);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
  );
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
  );

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const double spacingXS  = 4.0;
  static const double spacingS   = 8.0;
  static const double spacingM   = 12.0;
  static const double spacingL   = 16.0;
  static const double spacingXL  = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // ── Border Radius ─────────────────────────────────────────────────────────
  static const double radiusS   = 8.0;
  static const double radiusM   = 12.0;
  static const double radiusL   = 16.0;
  static const double radiusXL  = 20.0;
  static const double radiusXXL = 24.0;

  // ── Shadows ───────────────────────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get glowShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.18),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── Grade Utilities ───────────────────────────────────────────────────────
  static Color getGradeColor(String grade) {
    final n = grade.replaceAll(RegExp(r'[^0-9]'), '');
    const map = {
      '1': gradeColor1, '2': gradeColor2, '3': gradeColor3,
      '4': gradeColor4, '5': gradeColor5, '6': gradeColor6,
    };
    if (n.isNotEmpty) return map[n[0]] ?? textMuted;
    return textMuted;
  }

  static List<Color> get allGradeColors =>
      [gradeColor1, gradeColor2, gradeColor3, gradeColor4, gradeColor5, gradeColor6];

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary:          primaryColor,
        onPrimary:        Colors.white,
        secondary:        secondaryColor,
        onSecondary:      Colors.white,
        error:            errorColor,
        onError:          Colors.white,
        surface:          surfaceColor,
        onSurface:        textPrimary,
        outline:          borderColor,
        surfaceVariant:   cardColor,
        onSurfaceVariant: textSecondary,
        scrim:            Colors.black,
        shadow:           Colors.black,
        inverseSurface:   textPrimary,
        onInverseSurface: surfaceColor,
        inversePrimary:   primaryVariant,
        outlineVariant:   dividerColor,
      ),
      scaffoldBackgroundColor: bgColor,
      canvasColor: surfaceColor,
      cardColor: cardColor,

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: textSecondary, size: 22),
      ),

      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusL)),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusS)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        errorStyle: const TextStyle(color: errorColor, fontSize: 12),
        prefixIconColor: textMuted,
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(surfaceColor),
        headingTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.06);
          }
          return null;
        }),
        dataTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
        dividerThickness: 1,
        columnSpacing: 24,
        horizontalMargin: 20,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: const IconThemeData(color: primaryColor, size: 22),
        unselectedIconTheme: const IconThemeData(color: textMuted, size: 20),
        selectedLabelTextStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelTextStyle: const TextStyle(color: textMuted, fontSize: 13),
        indicatorColor: Color(0x2A3B82F6),
      ),

      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: textSecondary, size: 22),

      textTheme: const TextTheme(
        displayLarge:   TextStyle(fontSize: 32, fontWeight: FontWeight.bold,  color: textPrimary, letterSpacing: -0.5),
        displayMedium:  TextStyle(fontSize: 28, fontWeight: FontWeight.bold,  color: textPrimary, letterSpacing: -0.5),
        displaySmall:   TextStyle(fontSize: 24, fontWeight: FontWeight.bold,  color: textPrimary),
        headlineLarge:  TextStyle(fontSize: 22, fontWeight: FontWeight.w600,  color: textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,  color: textPrimary),
        headlineSmall:  TextStyle(fontSize: 18, fontWeight: FontWeight.w600,  color: textPrimary),
        titleLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w600,  color: textPrimary),
        titleMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500,  color: textPrimary),
        titleSmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w500,  color: textSecondary),
        bodyLarge:      TextStyle(fontSize: 16, color: textPrimary, height: 1.5),
        bodyMedium:     TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
        bodySmall:      TextStyle(fontSize: 12, color: textMuted, height: 1.4),
        labelLarge:     TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        labelMedium:    TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall:     TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusXL)),
          side: BorderSide(color: borderColor),
        ),
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        contentTextStyle: TextStyle(fontSize: 14, color: textSecondary, height: 1.5),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        behavior: SnackBarBehavior.floating,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return Colors.transparent;
        }),
        side: const BorderSide(color: borderColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withOpacity(0.2),
        disabledColor: borderColor,
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      popupMenuTheme: const PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusM)),
          side: BorderSide(color: borderColor),
        ),
        textStyle: TextStyle(color: textPrimary, fontSize: 14),
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: const Color(0xFFFFFFFF),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return primaryColor.withOpacity(0.04);
          return null;
        }),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1, space: 1),
    );
  }
}

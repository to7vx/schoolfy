import 'package:flutter/material.dart';

class AppTheme {
  // Color scheme
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color primaryVariant = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color accentColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color successColor = Color(0xFF4CAF50);
  
  // Grade colors
  static const Color gradeColor1 = Color(0xFFE53935);
  static const Color gradeColor2 = Color(0xFF1E88E5);
  static const Color gradeColor3 = Color(0xFF43A047);
  static const Color gradeColor4 = Color(0xFFFF9800);
  static const Color gradeColor5 = Color(0xFF8E24AA);
  static const Color gradeColor6 = Color(0xFF00ACC1);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(primaryColor.withOpacity(0.1)),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.05);
          }
          return null;
        }),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: false,
        shadowColor: Colors.black.withOpacity(0.5),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        color: const Color(0xFF1E1E1E),
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        labelStyle: TextStyle(color: Colors.grey.shade300),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(primaryColor.withOpacity(0.2)),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return primaryColor.withOpacity(0.1);
          }
          return null;
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedIconTheme: IconThemeData(
          color: primaryColor,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey.shade400,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
        ),
        indicatorColor: primaryColor.withOpacity(0.2),
      ),
    );
  }
  
  // Utility methods for grade colors
  static Color getGradeColor(String grade) {
    final gradeColors = {
      '1': gradeColor1,
      '2': gradeColor2,
      '3': gradeColor3,
      '4': gradeColor4,
      '5': gradeColor5,
      '6': gradeColor6,
    };
    
    final gradeNumber = grade.replaceAll(RegExp(r'[^0-9]'), '');
    if (gradeNumber.isNotEmpty) {
      return gradeColors[gradeNumber[0]] ?? Colors.grey.shade400;
    }
    return Colors.grey.shade400;
  }
  
  static List<Color> get allGradeColors => [
    gradeColor1, gradeColor2, gradeColor3, 
    gradeColor4, gradeColor5, gradeColor6
  ];
}

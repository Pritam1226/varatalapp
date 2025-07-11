import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color.fromARGB(255, 15, 181, 181);

  /* ───────────────────  LIGHT  ─────────────────── */
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: Color(0xFF8E8E93),
      surface: Colors.white,
      onSurface: Colors.black,
      tertiary: Color(0xFF7CBEC2),
      onPrimary: Colors.black87,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: primaryColor.withAlpha(25),           // 10 % opacity
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primaryColor),
      ),
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFCD1DA7).withAlpha(25),    // 10 % opacity
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    iconTheme: const IconThemeData(color: Colors.black87, size: 24),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      labelMedium: TextStyle(fontSize: 12, color: Color(0xFF603D3D)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  /* ───────────────────  DARK  ─────────────────── */
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: Color(0xFFAAAAAA),
      surface: Color(0xFF121212),
      onSurface: Colors.white,
      tertiary: Color(0xFF4EB7BA),
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[800],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primaryColor),
      ),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF2C2C2C),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    iconTheme: const IconThemeData(color: Colors.white, size: 24),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      labelMedium: TextStyle(fontSize: 12, color: Colors.white54),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

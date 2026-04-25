import 'package:flutter/material.dart';

class AppTheme {
  // --- PALETA PREMIUM: Midnight Black + Indigo / Cyan ---
  
  // Elementos principales e interacciones
  static const Color primaryColor = Color(0xFF6366F1);   // Indigo vibrante
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan (acentos/éxito sutil)
  static const Color accentBlue = Color(0xFF38BDF8);     // Light Blue accent
  
  // Fondos y Superficies (Capa por capa, de más oscuro a más claro)
  static const Color backgroundColor = Color(0xFF0A0A0A); // Fondo más profundo (Scaffold/App)
  static const Color surfaceColor = Color(0xFF171717);    // Elementos base y barras (AppBar/BottomNav)
  static const Color cardColor = Color(0xFF262626);       // Tarjetas elevadas, inputs
  
  // Estados y alertas
  static const Color successGreen = Color(0xFF10B981);    // Verde Esmeralda
  static const Color errorRed = Color(0xFFFF2E93);        // Cyber Pink (Rosa Neón para errores)
  
  // Topografía
  static const Color textWhite = Color(0xFFFAFAFA);       // Blanco puro para gran contraste
  static const Color textGrey = Color(0xFFA3A3A3);        // Gris neutro para texto secundario
  static const Color surfaceLight = Color(0xFFE5E7EB);    // Gris muy claro

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorRed,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textWhite,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          elevation: 6,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textGrey),
        prefixIconColor: secondaryColor,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: textWhite,
        elevation: 8,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textWhite, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineMedium: TextStyle(color: textWhite, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        titleLarge: TextStyle(color: textWhite, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textWhite, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textGrey, fontSize: 14, height: 1.4),
      ),
      iconTheme: const IconThemeData(
        color: textWhite,
        size: 24,
      ),
    );
  }
}

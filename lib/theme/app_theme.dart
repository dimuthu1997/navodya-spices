import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Tokens
  static const Color royalGoldPrimary = Color(0xFFA4721C); // Warm Royal Gold
  static const Color royalGoldAccent = Color(0xFFC8932F);  // Saffron Gold Accent
  static const Color cardamomGreen = Color(0xFF15803D);    // Emerald Spice Green
  static const Color whatsappGreen = Color(0xFF25D366);    // Official WhatsApp Green

  // Background & Card Colors - Light Mode
  static const Color bgCreamParchment = Color(0xFFFAF7F0); // Warm Natural Parchment
  static const Color cardLight = Color(0xFFFFFFFF);        // Pure White Card
  static const Color textDark = Color(0xFF1C1917);         // High-Contrast Dark Charcoal Text

  // Background & Card Colors - Dark Mode
  static const Color darkBg = Color(0xFF14110E);           // Deep Roasted Dark Coffee
  static const Color darkCard = Color(0xFF221D18);         // Dark Warm Mocha Card
  static const Color darkText = Color(0xFFFAFAFA);         // High-Contrast Crisp White Text

  // Backward Compatible Aliases
  static const Color saffronPrimary = royalGoldPrimary;
  static const Color saffronAccent = royalGoldAccent;
  static const Color turmericGold = royalGoldAccent;
  static const Color cinnamonBronze = royalGoldPrimary;

  // Light Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: royalGoldPrimary,
      scaffoldBackgroundColor: bgCreamParchment,
      cardColor: cardLight,
      colorScheme: const ColorScheme.light(
        primary: royalGoldPrimary,
        secondary: royalGoldAccent,
        surface: cardLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        bodyLarge: const TextStyle(color: textDark, fontSize: 16),
        bodyMedium: const TextStyle(color: textDark, fontSize: 14),
        titleLarge: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: textDark, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardLight,
        elevation: 1,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalGoldPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Dark Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: royalGoldPrimary,
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,
      colorScheme: const ColorScheme.dark(
        primary: royalGoldPrimary,
        secondary: royalGoldAccent,
        surface: darkCard,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: const TextStyle(color: darkText, fontSize: 16),
        bodyMedium: const TextStyle(color: darkText, fontSize: 14),
        titleLarge: const TextStyle(color: darkText, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: darkText, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCard,
        elevation: 1,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: royalGoldPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2C5BF0),
      brightness: Brightness.light,
      primary: const Color(0xFF2C5BF0),
      secondary: const Color(0xFF7A5CFA),
    );

    return ThemeData(
      colorScheme: colorScheme,
      textTheme: GoogleFonts.notoSansTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF3F5FF),
      useMaterial3: true,
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

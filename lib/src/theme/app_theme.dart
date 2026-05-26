import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B3A29),
      brightness: brightness,
    );
    final base = ThemeData(brightness: brightness, colorScheme: scheme);
    return base.copyWith(
      textTheme: GoogleFonts.crimsonProTextTheme(base.textTheme).copyWith(
        bodyLarge: GoogleFonts.crimsonPro(
          fontSize: 19,
          height: 1.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

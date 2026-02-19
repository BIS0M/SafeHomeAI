library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF2563EB);
  static const Color primary2 = Color(0xFF3B82F6);
  static const Color bg = Color(0xFFF5F6F8);
  static const Color gray900 = Color(0xFF1A1A1A);
  static const Color gray700 = Color(0xFF4A4A4A);

  // ✅ 친구의 폰트 가이드라인 (Display ~ Caption)
  static TextTheme get textTheme => TextTheme(
    displayLarge: GoogleFonts.notoSansKr(fontSize: 32, fontWeight: FontWeight.bold, height: 1.5, color: gray900),
    headlineLarge: GoogleFonts.notoSansKr(fontSize: 28, fontWeight: FontWeight.bold, height: 1.5, color: gray900),
    headlineMedium: GoogleFonts.notoSansKr(fontSize: 24, fontWeight: FontWeight.bold, height: 1.5, color: gray900),
    headlineSmall: GoogleFonts.notoSansKr(fontSize: 22, fontWeight: FontWeight.bold, height: 1.5, color: gray900),
    titleLarge: GoogleFonts.notoSansKr(fontSize: 19, fontWeight: FontWeight.w600, height: 1.5, color: gray900),
    bodyLarge: GoogleFonts.notoSansKr(fontSize: 19, fontWeight: FontWeight.w500, height: 1.5, color: gray700),
    bodyMedium: GoogleFonts.notoSansKr(fontSize: 17, fontWeight: FontWeight.w500, height: 1.5, color: gray700),
    bodySmall: GoogleFonts.notoSansKr(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5, color: gray700),
    labelLarge: GoogleFonts.notoSansKr(fontSize: 13, fontWeight: FontWeight.normal, height: 1.5, color: gray700),
    labelSmall: GoogleFonts.notoSansKr(fontSize: 11, fontWeight: FontWeight.normal, height: 1.5, color: gray700),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primary2,
        surface: Colors.white,
        error: Color(0xFFEF4444),
      ),
      // ✅ 일괄 적용된 텍스트 테마
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, thickness: 1),
    );
  }
}
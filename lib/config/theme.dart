import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Goldilocks-branded theme for the Goldi Card app.
class GoldiTheme {
  // ── Brand Colors ──────────────────────────────────────────────
  static const Color goldiYellow = Color(0xFFFFC72C);
  static const Color goldiYellowLight = Color(0xFFFFD75E);
  static const Color goldiYellowDark = Color(0xFFE6A800);
  static const Color goldiGold = Color(0xFFDAA520);
  static const Color goldiRed = Color(0xFFCE1126);
  static const Color warmWhite = Color(0xFFFFF8E7);
  static const Color warmCream = Color(0xFFFFF2CC);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color mediumBrown = Color(0xFF5D4037);
  static const Color lightBrown = Color(0xFF8D6E63);
  static const Color surfaceWhite = Color(0xFFFFFDF5);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFD32F2F);

  // ── Text Styles ───────────────────────────────────────────────
  static TextStyle get headingLarge => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: darkBrown,
        letterSpacing: -0.5,
      );

  static TextStyle get headingMedium => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkBrown,
      );

  static TextStyle get headingSmall => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkBrown,
      );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: mediumBrown,
      );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mediumBrown,
      );

  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: lightBrown,
      );

  static TextStyle get labelBold => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: darkBrown,
      );

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: darkBrown,
        letterSpacing: 0.5,
      );

  // ── Theme Data ────────────────────────────────────────────────
  static ThemeData get themeData => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldiYellow,
          primary: goldiYellow,
          onPrimary: darkBrown,
          secondary: goldiGold,
          surface: surfaceWhite,
          error: errorRed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surfaceWhite,
        appBarTheme: AppBarTheme(
          backgroundColor: goldiYellow,
          foregroundColor: darkBrown,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: darkBrown,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: goldiYellow,
            foregroundColor: darkBrown,
            elevation: 2,
            shadowColor: goldiYellowDark.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: warmWhite,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: goldiYellowDark.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: goldiYellowDark.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: goldiYellow, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: errorRed),
          ),
          labelStyle: GoogleFonts.poppins(
            color: mediumBrown,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.poppins(
            color: lightBrown.withValues(alpha: 0.7),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: goldiYellowDark.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: cardSurface,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: cardSurface,
        ),
      );

  // ── Decorations ───────────────────────────────────────────────
  static BoxDecoration get goldiGradientBackground => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [goldiYellow, warmCream, surfaceWhite],
          stops: [0.0, 0.3, 1.0],
        ),
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: goldiYellowDark.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get accentCardDecoration => BoxDecoration(
        gradient: const LinearGradient(
          colors: [goldiYellow, goldiYellowLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: goldiYellowDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
}

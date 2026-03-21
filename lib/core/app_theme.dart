import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color tokens ──────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF1B8B5A); // forest green
const kPrimaryLight = Color(0xFF26B573); // lighter green
const kPrimaryDark = Color(0xFF156B45); // deep green
const kAccent = Color(0xFF00C9A7); // mint-teal
const kError = Color(0xFFFF5C6A); // coral-red
const kWarning = Color(0xFFFF9500); // amber
const kInfo = Color(0xFF3B82F6); // blue (for info only)
const kGold = Color(0xFFFFB347);

// ─── Surface palette ───────────────────────────────────────────────────────────
const kBg = Color(0xFFF5F6FA);
const kSurface = Color(0xFFFFFFFF);
const kSurface2 = Color(0xFFF0F2F5);
const kBorder = Color(0xFFE4E7EF);
const kText = Color(0xFF0C1A12); // near-black with green undertone
const kTextSub = Color(0xFF5E7368);
const kTextMuted = Color(0xFFADBCB4);

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: kBg,
      colorScheme: const ColorScheme.light(
        primary: kPrimary,
        secondary: kAccent,
        tertiary: kWarning,
        error: kError,
        surface: kSurface,
        surfaceContainerHighest: kSurface2,
        outline: kBorder,
        onSurface: kText,
        onSurfaceVariant: kTextSub,
        shadow: Color(0xFF0A2018),
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: kText,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: kText),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kBorder, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kText,
          side: const BorderSide(color: kBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Dark variant so [themeModeProvider] still works; same green accent family.
  static ThemeData get dark {
    const darkBg = Color(0xFF0C1210);
    const darkSurface = Color(0xFF151C19);
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.dark(
        primary: kPrimaryLight,
        secondary: kAccent,
        tertiary: kWarning,
        error: kError,
        surface: darkSurface,
        surfaceContainerHighest: const Color(0xFF1E2823),
        outline: const Color(0xFF2A3830),
        onSurface: const Color(0xFFE8F0EC),
        onSurfaceVariant: const Color(0xFF9CAFA4),
        shadow: Colors.black,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: base.colorScheme.onSurface,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: base.colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: base.colorScheme.outline, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: kPrimaryLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base.colorScheme.onSurface,
          side: BorderSide(color: base.colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

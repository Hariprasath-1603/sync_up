/// Theme Configuration for SyncUp
/// Defines color schemes, typography, and component styles
/// Supports both light and dark themes with Material 3 design
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// BRAND COLORS
// ============================================================================
/// Primary brand color - used for CTAs, active states, and key UI elements
const Color kPrimary = Color(0xFF4A6CF7);

/// Light theme background color - subtle off-white for reduced eye strain
const Color kLightBackground = Color(0xFFF6F7FB);

/// Dark theme background color - deep dark for OLED displays
const Color kDarkBackground = Color(0xFF0B0E13);

// ============================================================================
// LIGHT THEME
// ============================================================================
/// Builds the light theme configuration
/// Uses Poppins font family for modern, clean typography
/// Includes custom button styles with rounded corners
ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);

  // Create color scheme from primary brand color
  final lightScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ).copyWith(primary: kPrimary, surface: kLightBackground);

  ButtonStyle baseFilledButtonStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  ButtonStyle baseOutlinedButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    side: BorderSide(color: Colors.grey.shade300),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  return base.copyWith(
    colorScheme: lightScheme,
    scaffoldBackgroundColor: kLightBackground,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: kLightBackground,
      foregroundColor: Colors.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(style: baseFilledButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: baseOutlinedButtonStyle,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: kLightBackground,
      indicatorColor: kPrimary.withOpacity(0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? kPrimary : Colors.grey.shade600,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    brightness: Brightness.light,
  );
}

ThemeData buildDarkAppTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

  final darkScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.dark,
  ).copyWith(primary: kPrimary, surface: kDarkBackground);

  ButtonStyle baseFilledButtonStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  ButtonStyle baseOutlinedButtonStyle = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    side: BorderSide(color: Colors.grey.shade700),
    textStyle: const TextStyle(fontWeight: FontWeight.w600),
  );

  return base.copyWith(
    colorScheme: darkScheme,
    scaffoldBackgroundColor: kDarkBackground,
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: kDarkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(style: baseFilledButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: baseOutlinedButtonStyle,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: kDarkBackground,
      indicatorColor: kPrimary.withOpacity(0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: isSelected ? kPrimary : Colors.grey.shade300,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );
      }),
    ),
    brightness: Brightness.dark,
  );
}

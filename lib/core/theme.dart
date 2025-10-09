import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Brand colors
const Color kPrimary = Color(0xFF4A6CF7); // Primary color
const Color kLightBackground = Color(0xFFF6F7FB);
const Color kDarkBackground = Color(0xFF0B0E13);

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);

  final lightScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.light,
  ).copyWith(
    primary: kPrimary,
    surface: kLightBackground,
    background: kLightBackground,
  );

  final darkScheme = ColorScheme.fromSeed(
    seedColor: kPrimary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: kPrimary,
    surface: kDarkBackground,
    background: kDarkBackground,
  );

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
    outlinedButtonTheme: OutlinedButtonThemeData(style: baseOutlinedButtonStyle),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: kLightBackground,
      indicatorColor: kPrimary.withOpacity(0.12),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(color: isSelected ? kPrimary : Colors.grey.shade600);
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
  ).copyWith(
    primary: kPrimary,
    surface: kDarkBackground,
    background: kDarkBackground,
  );

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
    outlinedButtonTheme: OutlinedButtonThemeData(style: baseOutlinedButtonStyle),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: kDarkBackground,
      indicatorColor: kPrimary.withOpacity(0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(color: isSelected ? kPrimary : Colors.grey.shade300);
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
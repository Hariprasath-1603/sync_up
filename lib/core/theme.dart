import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorSchemeSeed: const Color(0xFF2563EB), // modern blue
    useMaterial3: true,
  );
  return base.copyWith(
    textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
    scaffoldBackgroundColor: Colors.white,
  );
}

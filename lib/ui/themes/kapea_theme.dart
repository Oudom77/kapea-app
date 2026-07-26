import 'package:flutter/material.dart';

const kMaliciousColor = Color(0xFFA3313A);
const kSuspiciousColor = Color(0xFFD98A2B);
const kSafeColor = Color(0xFF1E7D46);
const kTeal = Color(0xFF0B6E63);
const kDeleteRed = Color(0xFFE0483E);
const kScreenshotBg = Color(0xFF3A3A3A);
const kBracketGreen = Color(0xFF34D399);

final apptheme = ThemeData(
  scaffoldBackgroundColor: const Color.fromARGB(255, 250, 250, 250),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111111)),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD2D2CC)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD2D2CC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF111111), width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: const Color(0xFF0B0B0B),
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

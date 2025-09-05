import 'package:flutter/material.dart';

/// Paleta del escudo + tokens semánticos para la UI
class AppColors {
  AppColors._();

  // --- Paleta base (desde el logo) ---
  static const Color navy = Color(0xFF011432);
  static const Color navyDark = Color(0xFF010F28);
  static const Color gold = Color(0xFFAB925F);
  static const Color maroon = Color(0xFF551E1E);
  static const Color cream = Color(0xFFF7F5EA);
  static const Color beige = Color(0xFFE4DFD2);
  static const Color white = Colors.white;

  // --- Tokens semánticos (usa estos en la UI) ---
  static const Color primary = navy;
  static const Color primaryDark = navyDark;
  static const Color secondary = gold;
  static const Color background = cream; // fondos de pantalla
  static const Color surface = white; // cards, inputs
  static const Color outline = beige; // bordes/divisores
  static const Color muted = Color(0xFF6B7280); // texto secundario

  // Estados (por si los necesitas)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
}

import 'package:flutter/material.dart';

/// Ilovaning rang palitrasi.
///
/// Bu yerdagi qiymatlar placeholder — brend dizayni tayyor bo'lgach
/// yangilanadi. Hech qanday joyda qattiq oq border (`Colors.white` chegara
/// sifatida) ishlatilmasligi kerak — loyihaning divider qoidasiga muvofiq.
abstract final class AppColors {
  static const Color primary = Color(0xFF1B5E20);
  static const Color secondary = Color(0xFF2E7D32);

  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  static const Color error = Color(0xFFB3261E);

  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}

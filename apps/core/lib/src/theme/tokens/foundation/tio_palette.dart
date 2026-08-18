import 'package:flutter/material.dart';

import '../primitive/tio_alpha.dart';

/// Canonical physical color registry for the Tio design system.
///
/// Semantic/theme/component layers must alias these exact values instead of
/// redefining raw ARGB colors independently.
class TioPalette {
  const TioPalette._();

  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const whiteAlpha179 =
      Color.fromARGB(TioAlpha.alpha179, 255, 255, 255);
  static const blackAlpha26 = Color.fromARGB(TioAlpha.alpha26, 0, 0, 0);
  static const blackAlpha80 = Color.fromARGB(TioAlpha.alpha80, 0, 0, 0);

  static const gray005 = Color(0xFF050505);
  static const gray016 = Color(0xFF101010);
  static const gray017 = Color(0xFF111111);
  static const gray031 = Color(0xFF1F1F1F);

  static const slate50 = Color(0xFFF8FAFC);

  static const neutral50 = Color(0xFFF9FAFB);
  static const neutral100 = Color(0xFFF3F4F6);
  static const neutral200 = Color(0xFFE5E7EB);
  static const neutral300 = Color(0xFFD1D5DB);
  static const neutral400 = Color(0xFF9CA3AF);
  static const neutral500 = Color(0xFF6B7280);
  static const neutral600 = Color(0xFF4B5563);
  static const neutral700 = Color(0xFF374151);
  static const neutral800 = Color(0xFF1F2937);
  static const neutral900 = Color(0xFF111827);
  static const neutral950 = Color(0xFF0B1120);

  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red550 = Color(0xFFE55757);
  static const red600 = Color(0xFFDC2626);

  static const green400 = Color(0xFF4ADE80);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);

  static const violet400 = Color(0xFFA78BFA);
  static const violet500 = Color(0xFF8B5CF6);

  static const cyan400 = Color(0xFF22D3EE);
  static const cyan500 = Color(0xFF06B6D4);

  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);

  static const sky400 = Color(0xFF38BDF8);
  static const sky600 = Color(0xFF0284C7);
}

import 'package:flutter/material.dart';

/// Tokens visuais do GoLog. As constantes antigas (COLOR_*) foram mantidas
/// para não quebrar nenhum uso existente; os novos tokens complementam a
/// paleta com tons de apoio, espaçamentos, raios e sombras padronizados.
class Styles {
  // --- Paleta base (legado) ---
  static const Color COLOR_LIGHTBLACK = Colors.black12;
  static const Color COLOR_BLACK = Colors.black;
  static const Color COLOR_BLACKBLUE = Color(0xFF1B2A47);
  static const Color COLOR_LIGHTGREEN = Color(0xFF28B498);
  static const Color COLOR_WHITE = Colors.white;
  static const Color COLOR_GRAY = Color(0xFF4A4A4A);
  static const Color COLOR_BACKGROUND = Color(0xFFF0F2F5);
  static const Color COLOR_RED = Color(0xFFFF3B30);
  static const Color COLOR_ORANGE = Color(0xFFFF9830);

  // --- Tons de apoio ---
  static const Color COLOR_BLACKBLUE_LIGHT = Color(0xFF2C3E63);
  static const Color COLOR_TEXT = Color(0xFF1B2A47);
  static const Color COLOR_TEXT_SECONDARY = Color(0xFF6B7385);
  static const Color COLOR_TEXT_HINT = Color(0xFFA0A6B4);
  static const Color COLOR_BORDER = Color(0xFFE2E6EC);
  static const Color COLOR_GREEN_SOFT = Color(0xFFE3F6F2);
  static const Color COLOR_ORANGE_SOFT = Color(0xFFFFF1E2);
  static const Color COLOR_RED_SOFT = Color(0xFFFFE9E7);
  static const Color COLOR_BLUE = Color(0xFF3D7BF7);
  static const Color COLOR_BLUE_SOFT = Color(0xFFE7EFFE);
  static const Color COLOR_GRAY_SOFT = Color(0xFFEDEFF3);

  // --- Espaçamentos (grid de 4) ---
  static const double SPACE_XS = 4;
  static const double SPACE_S = 8;
  static const double SPACE_M = 12;
  static const double SPACE_L = 16;
  static const double SPACE_XL = 24;
  static const double SPACE_XXL = 32;

  // --- Raios ---
  static const double RADIUS_S = 8;
  static const double RADIUS_M = 12;
  static const double RADIUS_L = 16;
  static const double RADIUS_XL = 24;

  // --- Sombras ---
  static const List<BoxShadow> SHADOW_CARD = [
    BoxShadow(color: Color(0x0F1B2A47), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> SHADOW_FLOATING = [
    BoxShadow(color: Color(0x261B2A47), blurRadius: 20, offset: Offset(0, 8)),
  ];

  // --- Tipografia ---
  static const TextStyle TITLE_L = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: COLOR_TEXT,
    letterSpacing: -0.3,
  );
  static const TextStyle TITLE_M = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: COLOR_TEXT,
  );
  static const TextStyle TITLE_S = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: COLOR_TEXT,
  );
  static const TextStyle BODY = TextStyle(
    fontSize: 14,
    color: COLOR_TEXT_SECONDARY,
    height: 1.35,
  );
  static const TextStyle CAPTION = TextStyle(
    fontSize: 12,
    color: COLOR_TEXT_SECONDARY,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle LABEL = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: COLOR_TEXT,
  );
}

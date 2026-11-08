import 'package:flutter/material.dart';

/// Couleurs relevées sur les maquettes (docs/Maquettes app santé.pdf).
abstract final class AppColors {
  /// Fond beige clair de toutes les pages.
  static const background = Color(0xFFF3F1EC);
  static const surface = Colors.white;
  static const outline = Color(0xFFDCD8CE);

  static const text = Color(0xFF1B2229);
  static const textMuted = Color(0xFF545B63);

  /// Vert-bleu « santé » : boutons principaux, médicaments.
  static const primary = Color(0xFF0E6B62);
  static const primaryDark = Color(0xFF0B4F48);
  static const primarySoft = Color(0xFFDCECE9);

  /// Bleu de l'hydratation.
  static const water = Color(0xFF1E5DA8);
  static const waterSoft = Color(0xFFE1EAF4);

  /// Badges de statut.
  static const success = Color(0xFF2C7A3F);
  static const successSoft = Color(0xFFE2F1E5);
  static const warning = Color(0xFF8A4A0B);
  static const warningSoft = Color(0xFFFBE8D3);
  static const neutral = Color(0xFF4A4F55);
  static const neutralSoft = Color(0xFFECEAE5);
  static const danger = Color(0xFFB3261E);
  static const dangerSoft = Color(0xFFF9DEDC);

  /// Deuxième couleur d'icône de médicament (violet de la maquette).
  static const accent = Color(0xFF6B4FA0);
  static const accentSoft = Color(0xFFECE6F4);
}

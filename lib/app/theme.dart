import 'package:flutter/material.dart';

/// Thème pensé pour des personnes âgées : texte grand, contrastes forts,
/// boutons hauts et faciles à toucher.
abstract final class AppTheme {
  static const _seed = Color(0xFF00796B); // vert-bleu « santé »

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed);
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 20),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 18),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );

    const minButtonSize = Size(64, 56);
    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButtonSize,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minButtonSize,
          textStyle: text.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 30)),
      ),
    );
  }
}

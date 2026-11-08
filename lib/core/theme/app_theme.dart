import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thème des maquettes, pensé pour des personnes âgées : police très
/// lisible (Atkinson Hyperlegible), texte grand, contrastes forts, boutons
/// hauts et arrondis, faciles à toucher.
abstract final class AppTheme {
  static const fontFamily = 'AtkinsonHyperlegible';
  static const radius = 20.0;
  static const buttonRadius = 16.0;

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.primarySoft,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.textMuted,
          outline: AppColors.outline,
          outlineVariant: AppColors.outline,
          error: AppColors.danger,
        );
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
    );
    final text = base.textTheme
        .copyWith(
          headlineMedium: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: const TextStyle(fontSize: 19, height: 1.35),
          bodyMedium: const TextStyle(fontSize: 17, height: 1.35),
          bodySmall: const TextStyle(fontSize: 15, height: 1.35),
          labelLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.text,
          displayColor: AppColors.text,
        );

    const minButtonSize = Size(64, 60);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
      borderSide: const BorderSide(color: AppColors.outline, width: 2),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(size: 28, color: AppColors.text),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minButtonSize,
          textStyle: text.labelLarge,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minButtonSize,
          textStyle: text.labelLarge,
          shape: buttonShape,
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.outline, width: 2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          textStyle: text.labelLarge?.copyWith(
            fontSize: 18,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.textMuted),
      ),
      chipTheme: ChipThemeData(
        labelStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        side: const BorderSide(color: AppColors.outline, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        showCheckmark: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            // « Médicaments » doit tenir sur une ligne (vérifié à 411 dp de large).
            letterSpacing: -0.4,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 28,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

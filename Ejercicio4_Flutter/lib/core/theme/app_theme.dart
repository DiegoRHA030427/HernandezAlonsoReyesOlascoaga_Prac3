import 'package:flutter/material.dart';

/// Temas institucionales. Son los mismos colores que usa el Ejercicio 2 y 3
/// (AppTheme.swift): Guinda ~ #9B023D y Azul ~ #003E80.
enum AppThemeOption {
  guinda('Guinda (IPN)', Color(0xFF9B023D)),
  azul('Azul (ESCOM)', Color(0xFF003E80));

  const AppThemeOption(this.displayName, this.accentColor);

  final String displayName;
  final Color accentColor;

  static AppThemeOption fromName(String? name) => AppThemeOption.values
      .firstWhere((t) => t.name == name, orElse: () => AppThemeOption.guinda);
}

/// Modo de apariencia. Por defecto se sigue el modo del sistema
/// (igual que `.preferredColorScheme(nil)` en SwiftUI).
enum AppearanceMode {
  system('Sistema', ThemeMode.system, Icons.brightness_auto),
  light('Claro', ThemeMode.light, Icons.light_mode),
  dark('Oscuro', ThemeMode.dark, Icons.dark_mode);

  const AppearanceMode(this.label, this.themeMode, this.icon);

  final String label;
  final ThemeMode themeMode;
  final IconData icon;

  static AppearanceMode fromName(String? name) => AppearanceMode.values
      .firstWhere((m) => m.name == name, orElse: () => AppearanceMode.system);
}

/// Construye el ThemeData claro y oscuro de cada tema.
/// Material 3 genera toda la paleta (fondos, superficies, texto) a partir del
/// color institucional, por eso ambos temas se adaptan solos al modo claro/oscuro.
class AppTheme {
  const AppTheme._();

  static ThemeData light(AppThemeOption option) =>
      _build(option, Brightness.light);

  static ThemeData dark(AppThemeOption option) =>
      _build(option, Brightness.dark);

  static ThemeData _build(AppThemeOption option, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    var scheme = ColorScheme.fromSeed(
      seedColor: option.accentColor,
      brightness: brightness,
    );
    if (isLight) {
      // En modo claro usamos el color institucional exacto como primario.
      // En modo oscuro Material 3 usa un tono más claro del mismo color
      // para mantener buen contraste sobre fondos oscuros.
      scheme = scheme.copyWith(
        primary: option.accentColor,
        onPrimary: Colors.white,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? option.accentColor : scheme.surface,
        foregroundColor: isLight ? Colors.white : scheme.primary,
      ),
    );
  }
}

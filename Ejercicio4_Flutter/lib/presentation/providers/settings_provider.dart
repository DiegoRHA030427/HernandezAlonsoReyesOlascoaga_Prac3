import 'package:flutter/foundation.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/repositories/preferences_repository.dart';

/// Preferencias de sesión persistentes (equivalente a SettingsStore.swift):
/// tema, modo claro/oscuro, criterio de orden y última carpeta visitada.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs)
      : _theme = AppThemeOption.fromName(_prefs.themeName),
        _appearance = AppearanceMode.fromName(_prefs.appearanceName),
        _sortOption = _prefs.sortOption,
        _lastVisitedPath = _prefs.lastVisitedPath;

  final PreferencesRepository _prefs;

  AppThemeOption _theme;
  AppearanceMode _appearance;
  SortOption _sortOption;
  String _lastVisitedPath;

  AppThemeOption get theme => _theme;
  AppearanceMode get appearance => _appearance;
  SortOption get sortOption => _sortOption;
  String get lastVisitedPath => _lastVisitedPath;

  Future<void> setTheme(AppThemeOption value) async {
    if (value == _theme) return;
    _theme = value;
    notifyListeners();
    await _prefs.setThemeName(value.name);
  }

  Future<void> setAppearance(AppearanceMode value) async {
    if (value == _appearance) return;
    _appearance = value;
    notifyListeners();
    await _prefs.setAppearanceName(value.name);
  }

  Future<void> setSortOption(SortOption value) async {
    if (value == _sortOption) return;
    _sortOption = value;
    notifyListeners();
    await _prefs.setSortOption(value);
  }

  Future<void> setLastVisitedPath(String value) async {
    if (value == _lastVisitedPath) return;
    _lastVisitedPath = value;
    notifyListeners();
    await _prefs.setLastVisitedPath(value);
  }
}

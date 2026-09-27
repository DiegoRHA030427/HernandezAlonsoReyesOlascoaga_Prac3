import '../entities/sort_option.dart';

/// Contrato del almacenamiento local de preferencias, favoritos y recientes
/// (equivalente a SettingsStore, FavoritesStore y RecentsStore del Ejercicio 2).
abstract class PreferencesRepository {
  String? get themeName;
  Future<void> setThemeName(String value);

  String? get appearanceName;
  Future<void> setAppearanceName(String value);

  SortOption get sortOption;
  Future<void> setSortOption(SortOption value);

  String get lastVisitedPath;
  Future<void> setLastVisitedPath(String value);

  List<String> get favoritePaths;
  Future<void> setFavoritePaths(List<String> value);

  List<String> get recentPaths;
  Future<void> setRecentPaths(List<String> value);

  bool get sampleContentCreated;
  Future<void> setSampleContentCreated(bool value);
}

import '../../domain/entities/sort_option.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/hive_preferences_datasource.dart';

/// Implementación del repositorio de preferencias sobre Hive.
class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl(this._ds);

  final HivePreferencesDataSource _ds;

  static const _theme = 'appTheme';
  static const _appearance = 'appearanceMode';
  static const _sort = 'sortOption';
  static const _lastVisited = 'lastVisitedPath';
  static const _favorites = 'favoritePaths';
  static const _recents = 'recentPaths';
  static const _sampleCreated = 'sampleContentCreated';

  @override
  String? get themeName => _ds.read<String>(_theme);
  @override
  Future<void> setThemeName(String value) => _ds.write(_theme, value);

  @override
  String? get appearanceName => _ds.read<String>(_appearance);
  @override
  Future<void> setAppearanceName(String value) => _ds.write(_appearance, value);

  @override
  SortOption get sortOption => SortOption.fromName(_ds.read<String>(_sort));
  @override
  Future<void> setSortOption(SortOption value) => _ds.write(_sort, value.name);

  @override
  String get lastVisitedPath => _ds.read<String>(_lastVisited) ?? '';
  @override
  Future<void> setLastVisitedPath(String value) => _ds.write(_lastVisited, value);

  @override
  List<String> get favoritePaths => _ds.readStringList(_favorites);
  @override
  Future<void> setFavoritePaths(List<String> value) => _ds.write(_favorites, value);

  @override
  List<String> get recentPaths => _ds.readStringList(_recents);
  @override
  Future<void> setRecentPaths(List<String> value) => _ds.write(_recents, value);

  @override
  bool get sampleContentCreated => _ds.read<bool>(_sampleCreated) ?? false;
  @override
  Future<void> setSampleContentCreated(bool value) =>
      _ds.write(_sampleCreated, value);
}

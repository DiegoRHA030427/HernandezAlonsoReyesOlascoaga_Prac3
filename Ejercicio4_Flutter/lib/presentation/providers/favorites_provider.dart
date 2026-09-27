import 'package:flutter/foundation.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/preferences_repository.dart';

/// Sistema de favoritos persistente (equivalente a FavoritesStore.swift).
class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider(this._prefs, this._files)
      : _paths = List<String>.of(_prefs.favoritePaths);

  final PreferencesRepository _prefs;
  final FileRepository _files;
  final List<String> _paths;
  List<FileItem> _items = const [];

  /// Favoritos que todavía existen en disco.
  List<FileItem> get items => _items;

  bool contains(String path) => _paths.contains(path);

  Future<void> toggle(String path) async {
    if (!_paths.remove(path)) _paths.add(path);
    notifyListeners();
    await _prefs.setFavoritePaths(List<String>.of(_paths));
    await refresh();
  }

  Future<void> remove(String path) async {
    _paths.remove(path);
    // Se quita de la lista visible de inmediato (lo necesita Dismissible).
    _items = _items.where((i) => i.path != path).toList();
    notifyListeners();
    await _prefs.setFavoritePaths(List<String>.of(_paths));
  }

  Future<void> refresh() async {
    final result = <FileItem>[];
    for (final path in _paths) {
      final item = await _files.getItem(path);
      if (item != null) result.add(item);
    }
    _items = result;
    notifyListeners();
  }
}

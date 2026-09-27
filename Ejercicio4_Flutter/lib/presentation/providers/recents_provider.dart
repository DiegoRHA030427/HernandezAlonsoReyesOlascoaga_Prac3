import 'package:flutter/foundation.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/preferences_repository.dart';

/// Historial de archivos recientes (equivalente a RecentsStore.swift, límite 25).
class RecentsProvider extends ChangeNotifier {
  RecentsProvider(this._prefs, this._files)
      : _paths = List<String>.of(_prefs.recentPaths);

  static const limit = 25;

  final PreferencesRepository _prefs;
  final FileRepository _files;
  final List<String> _paths;
  List<FileItem> _items = const [];

  List<FileItem> get items => _items;

  Future<void> add(String path) async {
    _paths
      ..remove(path)
      ..insert(0, path);
    if (_paths.length > limit) _paths.removeRange(limit, _paths.length);
    await _prefs.setRecentPaths(List<String>.of(_paths));
    await refresh();
  }

  Future<void> clear() async {
    _paths.clear();
    _items = const [];
    notifyListeners();
    await _prefs.setRecentPaths(const []);
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

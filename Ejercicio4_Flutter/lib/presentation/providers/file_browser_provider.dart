import 'package:flutter/foundation.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/errors/file_operation_exception.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/usecases/filter_and_sort_items.dart';

/// Lógica de una carpeta: listar, buscar, ordenar y ejecutar las acciones de
/// archivo (equivalente a FileBrowserViewModel.swift).
/// Las acciones lanzan FileOperationException y la pantalla muestra el mensaje.
class FileBrowserProvider extends ChangeNotifier {
  FileBrowserProvider({
    required FileRepository repository,
    required this.directoryPath,
  }) : _repository = repository;

  final FileRepository _repository;
  final String directoryPath;
  final FilterAndSortItems _filterAndSort = const FilterAndSortItems();

  List<FileItem> _items = [];
  String _query = '';
  bool _isLoading = true;
  String? _loadError;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get loadError => _loadError;
  String get query => _query;

  /// Resultado visible tras aplicar búsqueda y ordenamiento.
  List<FileItem> visibleItems(SortOption sort) =>
      _filterAndSort(_items, query: _query, sort: sort);

  void setQuery(String value) {
    _query = value;
    _notify();
  }

  Future<void> load() async {
    try {
      _items = await _repository.listDirectory(directoryPath);
      _loadError = null;
    } on FileOperationException catch (e) {
      _items = [];
      _loadError = e.message;
    }
    _isLoading = false;
    _notify();
  }

  Future<void> createFolder(String name) async {
    await _repository.createFolder(directoryPath, name);
    await load();
  }

  Future<void> rename(FileItem item, String newName) async {
    await _repository.rename(item, newName);
    await load();
  }

  Future<void> delete(FileItem item) async {
    // Se quita de la lista en el mismo frame (requisito de Dismissible);
    // después se recarga desde disco para reflejar el estado real.
    _items = _items.where((i) => i.path != item.path).toList();
    _notify();
    try {
      await _repository.delete(item);
    } finally {
      await load();
    }
  }

  /// Copia rápida dentro de la misma carpeta ("Duplicar").
  Future<void> duplicate(FileItem item) async {
    await _repository.copy(item, directoryPath);
    await load();
  }

  Future<void> copyTo(FileItem item, String destination) async {
    await _repository.copy(item, destination);
    await load();
  }

  Future<void> moveTo(FileItem item, String destination) async {
    await _repository.move(item, destination);
    await load();
  }

  Future<void> importFile(String fileName, Stream<List<int>> data) async {
    await _repository.importFile(
      fileName: fileName,
      data: data,
      destinationDir: directoryPath,
    );
    await load();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

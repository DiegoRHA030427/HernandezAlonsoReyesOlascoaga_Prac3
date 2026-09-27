import '../entities/file_item.dart';
import '../entities/sort_option.dart';

/// Caso de uso: búsqueda + ordenamiento de una carpeta
/// (equivalente a `displayedItems` en FileBrowserViewModel.swift).
class FilterAndSortItems {
  const FilterAndSortItems();

  List<FileItem> call(
    List<FileItem> items, {
    String query = '',
    SortOption sort = SortOption.name,
  }) {
    final q = query.trim().toLowerCase();
    final result = q.isEmpty
        ? List<FileItem>.of(items)
        : items.where((i) => i.name.toLowerCase().contains(q)).toList();

    switch (sort) {
      case SortOption.name:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SortOption.date:
        result.sort((a, b) => b.modified.compareTo(a.modified));
      case SortOption.size:
        result.sort((a, b) => b.size.compareTo(a.size));
    }
    return result;
  }
}

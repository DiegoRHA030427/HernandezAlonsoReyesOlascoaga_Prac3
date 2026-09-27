/// Criterios de ordenamiento (igual que SortOption.swift).
enum SortOption {
  name('Nombre'),
  date('Fecha'),
  size('Tamaño');

  const SortOption(this.label);

  final String label;

  static SortOption fromName(String? value) => SortOption.values
      .firstWhere((o) => o.name == value, orElse: () => SortOption.name);
}

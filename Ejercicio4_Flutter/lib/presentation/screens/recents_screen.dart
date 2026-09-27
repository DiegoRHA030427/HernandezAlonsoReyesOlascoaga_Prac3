import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../providers/recents_provider.dart';
import '../utils/file_opener.dart';
import '../widgets/empty_state.dart';
import '../widgets/file_row.dart';

/// Historial de archivos abiertos (equivalente a RecentsView del Ejercicio 2).
class RecentsScreen extends StatelessWidget {
  const RecentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recents = context.watch<RecentsProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final items = recents.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar historial',
            onPressed: items.isEmpty ? null : recents.clear,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: recents.refresh,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.history,
                    message: 'Aún no has abierto archivos.',
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return FileRow(
                    item: item,
                    isFavorite: favorites.contains(item.path),
                    onTap: () => openFileItem(context, item),
                  );
                },
              ),
      ),
    );
  }
}

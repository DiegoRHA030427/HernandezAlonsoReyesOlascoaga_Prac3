import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/file_item.dart';
import '../providers/favorites_provider.dart';
import '../utils/file_opener.dart';
import '../widgets/empty_state.dart';
import '../widgets/file_row.dart';
import 'file_browser_screen.dart';

/// Lista de favoritos persistentes (equivalente a FavoritesView del Ejercicio 2).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _open(BuildContext context, FileItem item) async {
    if (item.isDirectory) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FileBrowserScreen(directoryPath: item.path, title: item.name),
      ));
    } else {
      await openFileItem(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final items = favorites.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: RefreshIndicator(
        onRefresh: favorites.refresh,
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.star_outline,
                    message: 'No tienes archivos favoritos todavía.\n'
                        'Mantén presionado un archivo y elige "Agregar a favoritos", '
                        'o deslízalo hacia la derecha.',
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Dismissible(
                    key: ValueKey('fav-${item.path}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Theme.of(context).colorScheme.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.star_border, color: Colors.white),
                    ),
                    onDismissed: (_) => favorites.remove(item.path),
                    child: FileRow(
                      item: item,
                      isFavorite: true,
                      onTap: () => _open(context, item),
                      trailing: item.isDirectory ? const Icon(Icons.chevron_right) : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/storage_location.dart';
import '../../domain/repositories/file_repository.dart';
import '../widgets/empty_state.dart';
import 'file_browser_screen.dart';

/// Pantalla raíz: los tres directorios accesibles del sandbox
/// (igual que LocationsListView del Ejercicio 2).
class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  late final Future<List<StorageLocation>> _locations;

  @override
  void initState() {
    super.initState();
    _locations = context.read<FileRepository>().rootLocations();
  }

  IconData _icon(LocationType type) => switch (type) {
        LocationType.documents => Icons.snippet_folder_outlined,
        LocationType.inbox => Icons.move_to_inbox_outlined,
        LocationType.temporary => Icons.history_toggle_off,
      };

  String _description(LocationType type) => switch (type) {
        LocationType.documents => 'Documentos del usuario dentro de la app',
        LocationType.inbox => 'Archivos recibidos desde otras apps',
        LocationType.temporary => 'Temporales (el sistema puede borrarlos)',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Gestor de Archivos')),
      body: FutureBuilder<List<StorageLocation>>(
        future: _locations,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.warning_amber_rounded,
              message: 'No se pudieron abrir las carpetas de la app.\n${snapshot.error}',
            );
          }
          final locations = snapshot.data;
          if (locations == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Sandbox de la aplicación',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: scheme.primary),
                ),
              ),
              for (final location in locations)
                ListTile(
                  leading: Icon(_icon(location.type), color: scheme.primary, size: 30),
                  title: Text(location.name),
                  subtitle: Text(_description(location.type)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FileBrowserScreen(
                        directoryPath: location.path,
                        title: location.name,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

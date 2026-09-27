import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/repositories/file_repository.dart';
import '../widgets/empty_state.dart';

/// Mini navegador de carpetas para elegir el destino al copiar/mover
/// (equivalente a DestinationPickerView.swift). Devuelve la ruta elegida
/// con Navigator.pop, encadenando el resultado desde subcarpetas.
class DestinationPickerScreen extends StatefulWidget {
  const DestinationPickerScreen({
    super.key,
    required this.directoryPath,
    required this.title,
    this.isRoot = false,
  });

  final String directoryPath;
  final String title;
  final bool isRoot;

  @override
  State<DestinationPickerScreen> createState() => _DestinationPickerScreenState();
}

class _DestinationPickerScreenState extends State<DestinationPickerScreen> {
  late final Future<List<FileItem>> _folders;

  @override
  void initState() {
    super.initState();
    _folders = context
        .read<FileRepository>()
        .listDirectory(widget.directoryPath)
        .then((items) => items.where((i) => i.isDirectory).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
  }

  Future<void> _enter(FileItem folder) async {
    final result = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => DestinationPickerScreen(
        directoryPath: folder.path,
        title: folder.name,
      ),
    ));
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: widget.isRoot
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<FileItem>>(
        future: _folders,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(message: '${snapshot.error}', icon: Icons.warning_amber_rounded);
          }
          final folders = snapshot.data;
          if (folders == null) return const Center(child: CircularProgressIndicator());
          if (folders.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_open,
              message: 'No hay subcarpetas aquí.\n'
                  'Puedes elegir esta carpeta con el botón de abajo.',
            );
          }
          return ListView(
            children: [
              for (final folder in folders)
                ListTile(
                  leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.primary),
                  title: Text(folder.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _enter(folder),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Elegir esta carpeta'),
            onPressed: () => Navigator.of(context).pop(widget.directoryPath),
          ),
        ),
      ),
    );
  }
}

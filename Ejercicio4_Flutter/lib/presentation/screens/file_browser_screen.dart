import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/entities/sort_option.dart';
import '../../domain/errors/file_operation_exception.dart';
import '../../domain/repositories/file_repository.dart';
import '../providers/favorites_provider.dart';
import '../providers/file_browser_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/dialogs.dart';
import '../utils/file_opener.dart';
import '../widgets/empty_state.dart';
import '../widgets/file_row.dart';
import 'destination_picker_screen.dart';

/// Acciones disponibles en el menú contextual de un archivo.
enum _FileAction { favorite, rename, duplicate, copy, move, share, openWith, delete }

/// Vista principal de exploración (equivalente a FileBrowserView.swift):
/// lista, búsqueda, ordenamiento, gestos (deslizar, mantener presionado,
/// jalar para actualizar) y todas las acciones de archivo.
class FileBrowserScreen extends StatelessWidget {
  const FileBrowserScreen({
    super.key,
    required this.directoryPath,
    required this.title,
  });

  final String directoryPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FileBrowserProvider(
        repository: context.read<FileRepository>(),
        directoryPath: directoryPath,
      )..load(),
      child: _FileBrowserView(title: title),
    );
  }
}

class _FileBrowserView extends StatefulWidget {
  const _FileBrowserView({required this.title});

  final String title;

  @override
  State<_FileBrowserView> createState() => _FileBrowserViewState();
}

class _FileBrowserViewState extends State<_FileBrowserView> {
  final _searchController = TextEditingController();

  FileBrowserProvider get _browser => context.read<FileBrowserProvider>();

  @override
  void initState() {
    super.initState();
    // Preferencia de sesión: última carpeta visitada.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsProvider>().setLastVisitedPath(_browser.directoryPath);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ejecuta una acción y muestra el error (o el mensaje de éxito) en un SnackBar.
  Future<void> _run(Future<void> Function() action, {String? success}) async {
    try {
      await action();
      if (success != null && mounted) showSnack(context, success);
    } on FileOperationException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (e) {
      if (mounted) showSnack(context, 'Ocurrió un problema: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Acciones
  // ---------------------------------------------------------------------------

  Future<void> _createFolder() async {
    final name = await showTextInputDialog(context,
        title: 'Nueva carpeta', confirmLabel: 'Crear');
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => _browser.createFolder(name));
  }

  /// Importar desde el selector de archivos del sistema
  /// (equivalente a UIDocumentPickerViewController con asCopy: true).
  Future<void> _importFile() async {
    final picked = await FilePicker.pickFile();
    if (picked == null || !mounted) return;
    await _run(
      () => _browser.importFile(picked.name, picked.readAsByteStream()),
      success: 'Archivo importado',
    );
  }

  Future<void> _rename(FileItem item) async {
    final name = await showTextInputDialog(context,
        title: 'Renombrar', initialValue: item.name, hint: 'Nuevo nombre');
    if (name == null || name.isEmpty || !mounted) return;
    await _run(() => _browser.rename(item, name));
  }

  Future<void> _delete(FileItem item) async {
    final confirmed = await confirmDelete(context, item.name);
    if (!confirmed || !mounted) return;
    await _run(() => _browser.delete(item));
  }

  Future<void> _copyOrMove(FileItem item, {required bool move}) async {
    final repository = context.read<FileRepository>();
    final navigator = Navigator.of(context, rootNavigator: true);
    final documents = await repository.documentsPath();
    final destination = await navigator.push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DestinationPickerScreen(
          directoryPath: documents,
          title: move ? 'Mover a...' : 'Copiar a...',
          isRoot: true,
        ),
      ),
    );
    if (destination == null || !mounted) return;
    await _run(
      () => move ? _browser.moveTo(item, destination) : _browser.copyTo(item, destination),
      success: move ? 'Elemento movido' : 'Copia creada',
    );
  }

  /// Compartir / exportar (equivalente a UIActivityViewController).
  Future<void> _share(FileItem item) async {
    // En iPad la hoja de compartir necesita un punto de origen en pantalla.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(item.path)],
      text: item.name,
      sharePositionOrigin: origin,
    ));
  }

  Future<void> _open(FileItem item) async {
    if (item.isDirectory) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FileBrowserScreen(directoryPath: item.path, title: item.name),
      ));
    } else {
      await openFileItem(context, item);
    }
    // Al volver, recargamos por si algo cambió (edición, movimientos, etc.).
    if (mounted) await _browser.load();
  }

  /// Menú contextual al mantener presionado (equivalente a `.contextMenu`).
  Future<void> _showActions(FileItem item) async {
    final isFavorite = context.read<FavoritesProvider>().contains(item.path);
    final action = await showModalBottomSheet<_FileAction>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget tile(_FileAction action, IconData icon, String label, {Color? color}) {
          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(label, style: color == null ? null : TextStyle(color: color)),
            onTap: () => Navigator.of(sheetContext).pop(action),
          );
        }

        final errorColor = Theme.of(sheetContext).colorScheme.error;
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: FileThumbnail(item: item),
                  title: Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                tile(_FileAction.favorite, isFavorite ? Icons.star : Icons.star_border,
                    isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos'),
                tile(_FileAction.rename, Icons.edit_outlined, 'Renombrar'),
                tile(_FileAction.duplicate, Icons.control_point_duplicate, 'Duplicar'),
                tile(_FileAction.copy, Icons.folder_copy_outlined, 'Copiar a...'),
                if (!item.isDirectory) ...[
                  tile(_FileAction.move, Icons.drive_file_move_outlined, 'Mover a...'),
                  tile(_FileAction.share, Icons.share_outlined, 'Compartir'),
                  tile(_FileAction.openWith, Icons.open_in_new, 'Abrir con otra app'),
                ],
                tile(_FileAction.delete, Icons.delete_outline, 'Eliminar', color: errorColor),
              ],
            ),
          ),
        );
      },
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _FileAction.favorite:
        await context.read<FavoritesProvider>().toggle(item.path);
      case _FileAction.rename:
        await _rename(item);
      case _FileAction.duplicate:
        await _run(() => _browser.duplicate(item), success: 'Elemento duplicado');
      case _FileAction.copy:
        await _copyOrMove(item, move: false);
      case _FileAction.move:
        await _copyOrMove(item, move: true);
      case _FileAction.share:
        await _share(item);
      case _FileAction.openWith:
        await openWithSystem(context, item);
      case _FileAction.delete:
        await _delete(item);
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final browser = context.watch<FileBrowserProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final sort = context.select<SettingsProvider, SortOption>((s) => s.sortOption);
    final items = browser.visibleItems(sort);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar por',
            onSelected: (option) =>
                context.read<SettingsProvider>().setSortOption(option),
            itemBuilder: (_) => [
              for (final option in SortOption.values)
                CheckedPopupMenuItem(
                  value: option,
                  checked: option == sort,
                  child: Text(option.label),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Importar archivo',
            onPressed: _importFile,
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Nueva carpeta',
            onPressed: _createFolder,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: browser.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Buscar en ${widget.title}',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: browser.query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _searchController.clear();
                          browser.setQuery('');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          Expanded(
            // Jalar para actualizar (equivalente a `.refreshable`).
            child: RefreshIndicator(
              onRefresh: browser.load,
              child: _buildList(browser, items, favorites),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    FileBrowserProvider browser,
    List<FileItem> items,
    FavoritesProvider favorites,
  ) {
    // Todas las variantes son desplazables para que RefreshIndicator funcione.
    if (browser.isLoading && items.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 160),
        Center(child: CircularProgressIndicator()),
      ]);
    }
    if (browser.loadError != null || items.isEmpty) {
      final message = browser.loadError ??
          (browser.query.isNotEmpty
              ? 'Sin resultados para "${browser.query}".'
              : 'Esta carpeta está vacía.\nImporta un archivo o crea una carpeta con los botones de arriba.');
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(
            message: message,
            icon: browser.loadError != null
                ? Icons.warning_amber_rounded
                : Icons.folder_open,
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRow(item, favorites.contains(item.path));
      },
    );
  }

  /// Deslizar a la derecha = favorito; a la izquierda = eliminar (con confirmación).
  Widget _buildRow(FileItem item, bool isFavorite) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(item.path),
      background: _swipeBackground(
        alignment: Alignment.centerLeft,
        color: Colors.amber.shade700,
        icon: isFavorite ? Icons.star_border : Icons.star,
        label: isFavorite ? 'Quitar' : 'Favorito',
      ),
      secondaryBackground: _swipeBackground(
        alignment: Alignment.centerRight,
        color: scheme.error,
        icon: Icons.delete_outline,
        label: 'Eliminar',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await context.read<FavoritesProvider>().toggle(item.path);
          return false; // solo marca favorito, no quita la fila
        }
        return confirmDelete(context, item.name);
      },
      onDismissed: (_) => _run(() => _browser.delete(item)),
      child: FileRow(
        item: item,
        isFavorite: isFavorite,
        onTap: () => _open(item),
        onLongPress: () => _showActions(item),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Acciones',
          onPressed: () => _showActions(item),
        ),
      ),
    );
  }

  Widget _swipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

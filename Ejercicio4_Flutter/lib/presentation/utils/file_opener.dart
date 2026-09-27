import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/file_item.dart';
import '../providers/recents_provider.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/text_viewer_screen.dart';
import 'dialogs.dart';

/// Abre un archivo con el visor adecuado (igual que `openFile` del Ejercicio 2):
/// - Imagen -> visor propio con zoom.
/// - Texto  -> visor/editor propio.
/// - Otros  -> visor nativo del sistema (equivalente a QLPreviewController).
/// También lo registra en Recientes.
Future<void> openFileItem(BuildContext context, FileItem item) async {
  context.read<RecentsProvider>().add(item.path);
  final navigator = Navigator.of(context, rootNavigator: true);

  if (item.isImage) {
    await navigator.push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => ImageViewerScreen(item: item),
    ));
    return;
  }
  if (item.isText) {
    await navigator.push(MaterialPageRoute<void>(
      builder: (_) => TextViewerScreen(item: item),
    ));
    return;
  }
  await openWithSystem(context, item);
}

/// Vista previa con la app nativa del sistema (sin internet: usa apps instaladas).
Future<void> openWithSystem(BuildContext context, FileItem item) async {
  final result = await OpenFilex.open(item.path);
  if (result.type != ResultType.done && context.mounted) {
    showSnack(context,
        'No hay una app en el dispositivo para abrir este tipo de archivo.');
  }
}

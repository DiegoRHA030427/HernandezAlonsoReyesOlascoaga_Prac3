import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/file_item.dart';

/// Ícono según el tipo de archivo (equivalente a `systemImageName`).
IconData iconForKind(FileKind kind) => switch (kind) {
      FileKind.folder => Icons.folder,
      FileKind.image => Icons.image_outlined,
      FileKind.video => Icons.movie_outlined,
      FileKind.audio => Icons.graphic_eq,
      FileKind.pdf => Icons.picture_as_pdf_outlined,
      FileKind.code => Icons.code,
      FileKind.json => Icons.data_object,
      FileKind.text => Icons.description_outlined,
      FileKind.archive => Icons.folder_zip_outlined,
      FileKind.other => Icons.insert_drive_file_outlined,
    };

/// Fila de la lista de archivos (equivalente a FileRowView.swift).
class FileRow extends StatelessWidget {
  const FileRow({
    super.key,
    required this.item,
    required this.isFavorite,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  final FileItem item;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FileThumbnail(item: item),
      title: Row(
        children: [
          Flexible(
            child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (isFavorite)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.star, size: 14, color: Colors.amber),
            ),
        ],
      ),
      subtitle: Text(
        item.isDirectory
            ? 'Carpeta'
            : '${formatBytes(item.size)} · ${formatDate(item.modified)}',
      ),
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// Miniatura para imágenes o ícono por tipo.
///
/// Caché de miniaturas: `ResizeImage` decodifica la imagen a 120 px y el
/// ImageCache de Flutter la guarda en memoria, así la lista no vuelve a leer
/// ni decodificar el archivo completo (equivalente al NSCache del Ejercicio 2).
class FileThumbnail extends StatelessWidget {
  const FileThumbnail({super.key, required this.item});

  static const double size = 40;

  final FileItem item;

  @override
  Widget build(BuildContext context) {
    if (!item.isImage) return _icon(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image(
        image: ResizeImage(FileImage(File(item.path)), width: 120),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _icon(context),
      ),
    );
  }

  Widget _icon(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Icon(
        iconForKind(item.kind),
        size: 30,
        color: item.isDirectory ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

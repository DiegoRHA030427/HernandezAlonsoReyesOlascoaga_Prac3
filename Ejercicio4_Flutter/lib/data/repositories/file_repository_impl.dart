import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../../domain/entities/file_item.dart';
import '../../domain/entities/storage_location.dart';
import '../../domain/errors/file_operation_exception.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/sample_content.dart';
import '../datasources/sandbox_paths_datasource.dart';

/// Implementación de las operaciones de archivos con dart:io
/// (equivalente a FileSystemService.swift con FileManager).
/// Solo trabaja dentro del sandbox de la app.
class FileRepositoryImpl implements FileRepository {
  FileRepositoryImpl(this._paths);

  final SandboxPathsDataSource _paths;

  @override
  Future<List<StorageLocation>> rootLocations() async {
    final docs = await _paths.documents();
    final inbox = await _paths.inbox();
    final tmp = await _paths.temporary();
    return [
      StorageLocation(name: 'Documents', path: docs.path, type: LocationType.documents),
      StorageLocation(name: 'Inbox', path: inbox.path, type: LocationType.inbox),
      StorageLocation(name: 'Temporal (tmp)', path: tmp.path, type: LocationType.temporary),
    ];
  }

  @override
  Future<String> documentsPath() async => (await _paths.documents()).path;

  @override
  Future<List<FileItem>> listDirectory(String path) async {
    try {
      final entities = await Directory(path).list(followLinks: false).toList();
      final items = <FileItem>[];
      for (final entity in entities) {
        final name = p.basename(entity.path);
        // Igual que `.skipsHiddenFiles` en el Ejercicio 2.
        if (name.startsWith('.')) continue;
        // En Android (modo debug) Flutter guarda sus recursos internos en la
        // misma carpeta que getApplicationDocumentsDirectory(); no son del usuario.
        if (_isFlutterInternal(name)) continue;
        items.add(await _toItem(entity.path));
      }
      return items;
    } on FileSystemException catch (e) {
      throw FileOperationException('No se pudo leer la carpeta: ${_reason(e)}');
    }
  }

  @override
  Future<FileItem?> getItem(String path) async {
    if (!await _exists(path)) return null;
    return _toItem(path);
  }

  @override
  Future<void> createFolder(String parentPath, String name) async {
    final clean = _validateName(name);
    final target = p.join(parentPath, clean);
    if (await _exists(target)) {
      throw const FileOperationException('Ya existe un elemento con ese nombre.');
    }
    await _guard('crear la carpeta', () => Directory(target).create());
  }

  @override
  Future<void> rename(FileItem item, String newName) async {
    final clean = _validateName(newName);
    if (clean == item.name) return;
    final target = p.join(p.dirname(item.path), clean);
    final onlyCaseChanges = target.toLowerCase() == item.path.toLowerCase();
    if (!onlyCaseChanges && await _exists(target)) {
      throw const FileOperationException('Ya existe un elemento con ese nombre.');
    }
    await _guard('renombrar', () async {
      if (item.isDirectory) {
        await Directory(item.path).rename(target);
      } else {
        await File(item.path).rename(target);
      }
    });
  }

  @override
  Future<void> delete(FileItem item) => _guard('eliminar', () async {
        if (item.isDirectory) {
          await Directory(item.path).delete(recursive: true);
        } else {
          await File(item.path).delete();
        }
      });

  @override
  Future<void> copy(FileItem item, String destinationDir) async {
    if (item.isDirectory && _isSameOrInside(item.path, destinationDir)) {
      throw const FileOperationException(
          'No puedes copiar una carpeta dentro de sí misma.');
    }
    final target = await _uniqueDestination(item.name, destinationDir);
    await _guard('copiar', () async {
      if (item.isDirectory) {
        await _copyDirectory(Directory(item.path), Directory(target));
      } else {
        await File(item.path).copy(target);
      }
    });
  }

  @override
  Future<void> move(FileItem item, String destinationDir) async {
    if (p.equals(p.dirname(item.path), destinationDir)) return; // ya está ahí
    if (item.isDirectory && _isSameOrInside(item.path, destinationDir)) {
      throw const FileOperationException(
          'No puedes mover una carpeta dentro de sí misma.');
    }
    final target = await _uniqueDestination(item.name, destinationDir);
    await _guard('mover', () async {
      try {
        if (item.isDirectory) {
          await Directory(item.path).rename(target);
        } else {
          await File(item.path).rename(target);
        }
      } on FileSystemException {
        // rename falla entre volúmenes distintos (p. ej. Documents -> cache en
        // algunos Android): en ese caso copiamos y luego borramos el original.
        if (item.isDirectory) {
          await _copyDirectory(Directory(item.path), Directory(target));
          await Directory(item.path).delete(recursive: true);
        } else {
          await File(item.path).copy(target);
          await File(item.path).delete();
        }
      }
    });
  }

  @override
  Future<void> importFile({
    required String fileName,
    required Stream<List<int>> data,
    required String destinationDir,
  }) async {
    final target = await _uniqueDestination(p.basename(fileName), destinationDir);
    final file = File(target);
    try {
      final sink = file.openWrite();
      try {
        await sink.addStream(data);
      } finally {
        await sink.close();
      }
    } catch (e) {
      // Si la copia se interrumpe, no dejamos un archivo a medias.
      if (await file.exists()) await file.delete();
      throw FileOperationException('No se pudo importar el archivo: $e');
    }
  }

  @override
  Future<String> readText(String path) async {
    try {
      return await File(path).readAsString();
    } on FormatException {
      throw const FileOperationException(
          'No se pudo leer el archivo como texto (no es UTF-8).');
    } on FileSystemException catch (e) {
      throw FileOperationException('No se pudo leer el archivo: ${_reason(e)}');
    }
  }

  @override
  Future<void> writeText(String path, String content) =>
      _guard('guardar el archivo', () => File(path).writeAsString(content, flush: true));

  @override
  Future<void> createSampleContent() async {
    final docs = (await _paths.documents()).path;
    await _paths.inbox();

    Future<void> writeIfMissing(String name, String content) async {
      final file = File(p.join(docs, name));
      if (!await file.exists()) await file.writeAsString(content);
    }

    await writeIfMissing('Bienvenida.txt', welcomeText);
    await writeIfMissing('Notas.md', notesMarkdown);
    await writeIfMissing('datos_ejemplo.json', sampleJson);

    final proyectos = Directory(p.join(docs, 'Proyectos'));
    await proyectos.create(recursive: true);
    final pendientes = File(p.join(proyectos.path, 'pendientes.txt'));
    if (!await pendientes.exists()) await pendientes.writeAsString(pendingText);

    final image = File(p.join(docs, 'imagen_muestra.png'));
    if (!await image.exists()) {
      final data = await rootBundle.load('assets/muestras/imagen_muestra.png');
      await image.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
  }

  // ---------------------------------------------------------------------------
  // Utilidades privadas
  // ---------------------------------------------------------------------------

  Future<FileItem> _toItem(String path) async {
    final stat = await FileStat.stat(path);
    final isDir = stat.type == FileSystemEntityType.directory;
    final name = p.basename(path);
    return FileItem(
      path: path,
      name: name,
      isDirectory: isDir,
      size: isDir ? 0 : stat.size,
      modified: stat.modified,
      kind: FileItem.kindFor(name, isDirectory: isDir),
    );
  }

  bool _isFlutterInternal(String name) =>
      name == 'flutter_assets' || name.startsWith('res_timestamp-');

  Future<bool> _exists(String path) async =>
      await FileSystemEntity.type(path, followLinks: false) !=
      FileSystemEntityType.notFound;

  bool _isSameOrInside(String source, String destination) =>
      p.equals(source, destination) || p.isWithin(source, destination);

  String _validateName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) {
      throw const FileOperationException('El nombre no puede estar vacío.');
    }
    if (clean.contains('/') || clean.contains(r'\') || clean == '.' || clean == '..') {
      throw const FileOperationException('El nombre contiene caracteres no válidos.');
    }
    return clean;
  }

  /// Evita sobrescribir archivos con el mismo nombre agregando "(1)", "(2)", etc.
  Future<String> _uniqueDestination(String name, String directory) async {
    final base = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    var candidate = p.join(directory, name);
    var counter = 1;
    while (await _exists(candidate)) {
      candidate = p.join(directory, '$base ($counter)$ext');
      counter++;
    }
    return candidate;
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  Future<void> _guard(String action, Future<void> Function() operation) async {
    try {
      await operation();
    } on FileSystemException catch (e) {
      throw FileOperationException('No se pudo $action: ${_reason(e)}');
    }
  }

  String _reason(FileSystemException e) => e.osError?.message ?? e.message;
}

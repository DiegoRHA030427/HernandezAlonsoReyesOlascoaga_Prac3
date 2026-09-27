import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resuelve las carpetas del sandbox de la app en cada plataforma:
/// - iOS:     <App>/Documents, <App>/Documents/Inbox y <App>/tmp (igual que el Ejercicio 2).
/// - Android: /data/data/<paquete>/app_flutter, .../app_flutter/Inbox y /data/data/<paquete>/cache.
/// La app nunca sale de estas rutas (no pide permisos de almacenamiento externo).
abstract class SandboxPathsDataSource {
  Future<Directory> documents();
  Future<Directory> inbox();
  Future<Directory> temporary();
}

class PathProviderSandboxPaths implements SandboxPathsDataSource {
  @override
  Future<Directory> documents() => getApplicationDocumentsDirectory();

  /// La creamos si no existe para poder explorarla desde el primer arranque,
  /// igual que `inboxURL` en FileSystemService.swift.
  @override
  Future<Directory> inbox() async {
    final dir = Directory(p.join((await documents()).path, 'Inbox'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<Directory> temporary() => getTemporaryDirectory();
}

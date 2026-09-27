import '../entities/file_item.dart';
import '../entities/storage_location.dart';

/// Contrato de las operaciones de archivos (equivalente a FileSystemService.swift).
/// La capa de presentación solo conoce esta interfaz, no dart:io.
abstract class FileRepository {
  Future<List<StorageLocation>> rootLocations();

  Future<String> documentsPath();

  Future<List<FileItem>> listDirectory(String path);

  /// Devuelve null si el archivo ya no existe.
  Future<FileItem?> getItem(String path);

  Future<void> createFolder(String parentPath, String name);

  Future<void> rename(FileItem item, String newName);

  Future<void> delete(FileItem item);

  /// Copia (o duplica, si el destino es la misma carpeta) sin sobrescribir.
  Future<void> copy(FileItem item, String destinationDir);

  Future<void> move(FileItem item, String destinationDir);

  /// Copia al sandbox un archivo externo elegido con el selector del sistema.
  /// Se recibe como flujo de bytes porque en Android el selector puede
  /// entregar un `content://` sin ruta local.
  Future<void> importFile({
    required String fileName,
    required Stream<List<int>> data,
    required String destinationDir,
  });

  Future<String> readText(String path);

  Future<void> writeText(String path, String content);

  /// Crea archivos de ejemplo la primera vez que se abre la app.
  Future<void> createSampleContent();
}

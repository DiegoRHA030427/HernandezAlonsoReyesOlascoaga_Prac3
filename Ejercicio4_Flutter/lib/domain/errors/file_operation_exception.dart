/// Error de negocio con un mensaje listo para mostrarse al usuario.
class FileOperationException implements Exception {
  const FileOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

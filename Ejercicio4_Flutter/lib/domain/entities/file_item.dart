/// Tipo de archivo, deducido por extensión (equivalente al UTType del Ejercicio 2).
enum FileKind { folder, image, video, audio, pdf, code, json, text, archive, other }

/// Representa un archivo o carpeta dentro del sandbox de la app
/// (equivalente a FileSystemItem.swift). Es Dart puro: no depende de Flutter.
class FileItem {
  const FileItem({
    required this.path,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
    required this.kind,
  });

  final String path;
  final String name;
  final bool isDirectory;
  final int size;
  final DateTime modified;
  final FileKind kind;

  bool get isImage => kind == FileKind.image;

  bool get isText =>
      kind == FileKind.text || kind == FileKind.code || kind == FileKind.json;

  static const _imageExt = {'png', 'jpg', 'jpeg', 'gif', 'heic', 'bmp', 'webp'};
  static const _videoExt = {'mp4', 'mov', 'm4v', 'avi', 'mkv', '3gp', 'webm'};
  static const _audioExt = {'mp3', 'm4a', 'wav', 'aac', 'ogg', 'flac'};
  static const _codeExt = {
    'swift', 'dart', 'kt', 'kts', 'java', 'py', 'js', 'ts', 'c', 'cpp', 'h',
    'html', 'css', 'xml', 'yaml', 'yml', 'sh', 'gradle',
  };
  static const _textExt = {'txt', 'md', 'csv', 'log'};
  static const _archiveExt = {'zip', 'rar', '7z', 'tar', 'gz'};

  static FileKind kindFor(String name, {required bool isDirectory}) {
    if (isDirectory) return FileKind.folder;
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) return FileKind.other;
    final ext = name.substring(dot + 1).toLowerCase();
    if (_imageExt.contains(ext)) return FileKind.image;
    if (_videoExt.contains(ext)) return FileKind.video;
    if (_audioExt.contains(ext)) return FileKind.audio;
    if (ext == 'pdf') return FileKind.pdf;
    if (ext == 'json') return FileKind.json;
    if (_codeExt.contains(ext)) return FileKind.code;
    if (_textExt.contains(ext)) return FileKind.text;
    if (_archiveExt.contains(ext)) return FileKind.archive;
    return FileKind.other;
  }

  @override
  bool operator ==(Object other) =>
      other is FileItem && other.path == path && other.modified == modified;

  @override
  int get hashCode => Object.hash(path, modified);
}

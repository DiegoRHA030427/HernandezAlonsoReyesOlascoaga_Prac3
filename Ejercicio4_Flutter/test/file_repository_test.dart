import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_archivos/data/datasources/sandbox_paths_datasource.dart';
import 'package:gestor_archivos/data/repositories/file_repository_impl.dart';
import 'package:gestor_archivos/domain/entities/file_item.dart';
import 'package:gestor_archivos/domain/entities/sort_option.dart';
import 'package:gestor_archivos/domain/errors/file_operation_exception.dart';
import 'package:gestor_archivos/domain/usecases/filter_and_sort_items.dart';
import 'package:path/path.dart' as p;

/// Sandbox falso sobre una carpeta temporal (no necesita path_provider).
class FakeSandboxPaths implements SandboxPathsDataSource {
  FakeSandboxPaths(this.root);

  final Directory root;

  @override
  Future<Directory> documents() async => root;

  @override
  Future<Directory> inbox() async =>
      Directory(p.join(root.path, 'Inbox'))..createSync(recursive: true);

  @override
  Future<Directory> temporary() async => Directory.systemTemp;
}

void main() {
  late Directory root;
  late FileRepositoryImpl repo;

  setUp(() {
    root = Directory.systemTemp.createTempSync('gestor_test_');
    repo = FileRepositoryImpl(FakeSandboxPaths(root));
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<FileItem> itemAt(String name) async =>
      (await repo.getItem(p.join(root.path, name)))!;

  test('crea carpetas y lista el contenido sin archivos ocultos', () async {
    await repo.createFolder(root.path, 'Proyectos');
    File(p.join(root.path, '.oculto')).writeAsStringSync('x');
    Directory(p.join(root.path, 'flutter_assets')).createSync();
    File(p.join(root.path, 'res_timestamp-1-123')).writeAsStringSync('');
    File(p.join(root.path, 'nota.txt')).writeAsStringSync('hola');

    final items = await repo.listDirectory(root.path);

    expect(items.map((i) => i.name).toSet(), {'Proyectos', 'nota.txt'});
    expect(items.firstWhere((i) => i.name == 'Proyectos').isDirectory, isTrue);
  });

  test('duplicar no sobrescribe: agrega (1), (2)...', () async {
    File(p.join(root.path, 'nota.txt')).writeAsStringSync('hola');
    final item = await itemAt('nota.txt');

    await repo.copy(item, root.path);
    await repo.copy(item, root.path);

    final names = (await repo.listDirectory(root.path)).map((i) => i.name).toSet();
    expect(names, {'nota.txt', 'nota (1).txt', 'nota (2).txt'});
  });

  test('renombrar a un nombre que ya existe lanza error', () async {
    File(p.join(root.path, 'a.txt')).writeAsStringSync('a');
    File(p.join(root.path, 'b.txt')).writeAsStringSync('b');

    expect(() async => repo.rename(await itemAt('a.txt'), 'b.txt'),
        throwsA(isA<FileOperationException>()));
  });

  test('no permite copiar una carpeta dentro de sí misma', () async {
    await repo.createFolder(root.path, 'Carpeta');
    final folder = await itemAt('Carpeta');

    expect(() => repo.copy(folder, folder.path), throwsA(isA<FileOperationException>()));
  });

  test('mueve un archivo a una subcarpeta', () async {
    await repo.createFolder(root.path, 'Destino');
    File(p.join(root.path, 'foto.png')).writeAsBytesSync([1, 2, 3]);

    await repo.move(await itemAt('foto.png'), p.join(root.path, 'Destino'));

    expect(File(p.join(root.path, 'foto.png')).existsSync(), isFalse);
    expect(File(p.join(root.path, 'Destino', 'foto.png')).existsSync(), isTrue);
  });

  test('importa un archivo desde un flujo de bytes sin sobrescribir', () async {
    File(p.join(root.path, 'foto.png')).writeAsBytesSync([9]);

    await repo.importFile(
      fileName: 'foto.png',
      data: Stream.value([1, 2, 3]),
      destinationDir: root.path,
    );

    final imported = File(p.join(root.path, 'foto (1).png'));
    expect(imported.readAsBytesSync(), [1, 2, 3]);
    expect(File(p.join(root.path, 'foto.png')).readAsBytesSync(), [9]);
  });

  test('lee y escribe archivos de texto', () async {
    final path = p.join(root.path, 'notas.md');
    await repo.writeText(path, '# Hola ESCOM');
    expect(await repo.readText(path), '# Hola ESCOM');
  });

  test('FilterAndSortItems busca y ordena', () {
    FileItem make(String name, int size, int day) => FileItem(
          path: '/x/$name',
          name: name,
          isDirectory: false,
          size: size,
          modified: DateTime(2026, 9, day),
          kind: FileItem.kindFor(name, isDirectory: false),
        );
    final items = [make('b.txt', 10, 1), make('A.png', 30, 3), make('c.json', 20, 2)];
    const useCase = FilterAndSortItems();

    expect(useCase(items).map((i) => i.name), ['A.png', 'b.txt', 'c.json']);
    expect(useCase(items, sort: SortOption.size).first.name, 'A.png');
    expect(useCase(items, sort: SortOption.date).last.name, 'b.txt');
    expect(useCase(items, query: 'JSON').single.name, 'c.json');
  });

  test('detecta el tipo de archivo por extensión', () {
    expect(FileItem.kindFor('foto.JPG', isDirectory: false), FileKind.image);
    expect(FileItem.kindFor('main.dart', isDirectory: false), FileKind.code);
    expect(FileItem.kindFor('datos.json', isDirectory: false), FileKind.json);
    expect(FileItem.kindFor('Proyectos', isDirectory: true), FileKind.folder);
    expect(FileItem.kindFor('sin_extension', isDirectory: false), FileKind.other);
  });
}

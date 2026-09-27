import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_archivos/core/theme/app_theme.dart';
import 'package:gestor_archivos/domain/entities/file_item.dart';
import 'package:gestor_archivos/presentation/widgets/file_row.dart';

void main() {
  testWidgets('FileRow muestra nombre, tamaño y estrella de favorito', (tester) async {
    final item = FileItem(
      path: '/sandbox/notas.txt',
      name: 'notas.txt',
      isDirectory: false,
      size: 2048,
      modified: DateTime(2026, 9, 27, 10, 30),
      kind: FileKind.text,
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(AppThemeOption.guinda),
      home: Scaffold(body: FileRow(item: item, isFavorite: true)),
    ));

    expect(find.text('notas.txt'), findsOneWidget);
    expect(find.textContaining('2.0 KB'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  test('Los temas usan los colores institucionales y soportan modo oscuro', () {
    expect(AppTheme.light(AppThemeOption.guinda).colorScheme.primary, const Color(0xFF9B023D));
    expect(AppTheme.light(AppThemeOption.azul).colorScheme.primary, const Color(0xFF003E80));
    expect(AppTheme.dark(AppThemeOption.guinda).colorScheme.brightness, Brightness.dark);
    expect(AppTheme.dark(AppThemeOption.azul).colorScheme.brightness, Brightness.dark);
  });
}

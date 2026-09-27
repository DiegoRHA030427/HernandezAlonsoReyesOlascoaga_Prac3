import 'package:flutter/material.dart';

import 'app.dart';
import 'data/datasources/hive_preferences_datasource.dart';
import 'data/datasources/sandbox_paths_datasource.dart';
import 'data/repositories/file_repository_impl.dart';
import 'data/repositories/preferences_repository_impl.dart';

/// Punto de entrada. Aquí se "inyectan" las dependencias de la capa de datos
/// para que la presentación solo conozca los contratos del dominio.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = PreferencesRepositoryImpl(await HivePreferencesDataSource.open());
  final files = FileRepositoryImpl(PathProviderSandboxPaths());

  // La primera vez se crean archivos de ejemplo para probar los visores sin internet.
  if (!preferences.sampleContentCreated) {
    try {
      await files.createSampleContent();
    } catch (e) {
      debugPrint('No se pudo crear el contenido de ejemplo: $e');
    }
    await preferences.setSampleContentCreated(true);
  }

  runApp(GestorArchivosApp(fileRepository: files, preferencesRepository: preferences));
}

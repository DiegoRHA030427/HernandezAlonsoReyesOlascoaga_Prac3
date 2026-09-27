import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

/// Ajustes: tema institucional, modo claro/oscuro y preferencias de sesión
/// (equivalente a SettingsView del Ejercicio 2).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(text, style: textTheme.titleSmall?.copyWith(color: scheme.primary)),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          sectionTitle('Tema'),
          SegmentedButton<AppThemeOption>(
            segments: [
              for (final theme in AppThemeOption.values)
                ButtonSegment(
                  value: theme,
                  label: Text(theme.displayName),
                  icon: Icon(Icons.circle, color: theme.accentColor),
                ),
            ],
            selected: {settings.theme},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => settings.setTheme(selection.first),
          ),
          const SizedBox(height: 20),
          sectionTitle('Modo claro / oscuro'),
          SegmentedButton<AppearanceMode>(
            segments: [
              for (final mode in AppearanceMode.values)
                ButtonSegment(value: mode, label: Text(mode.label), icon: Icon(mode.icon)),
            ],
            selected: {settings.appearance},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => settings.setAppearance(selection.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Por defecto la app sigue el modo del sistema. Ambos temas tienen '
              'versión clara y oscura.',
              style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          sectionTitle('Preferencias de sesión'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: const Text('Última carpeta visitada'),
                  subtitle: Text(settings.lastVisitedPath.isEmpty
                      ? '—'
                      : p.basename(settings.lastVisitedPath)),
                ),
                ListTile(
                  leading: const Icon(Icons.sort),
                  title: const Text('Ordenar por'),
                  subtitle: Text(settings.sortOption.label),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          sectionTitle('Acerca de'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Gestor de Archivos — Práctica 3, Ejercicio 4 (Flutter)'),
              subtitle: Text(
                'IPN · ESCOM — Desarrollo de Aplicaciones Móviles Nativas\n'
                'Funciona 100 % sin conexión: los archivos viven en el sandbox '
                'de la app y las preferencias en Hive.',
              ),
              isThreeLine: true,
            ),
          ),
        ],
      ),
    );
  }
}

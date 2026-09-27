import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'domain/repositories/file_repository.dart';
import 'domain/repositories/preferences_repository.dart';
import 'presentation/providers/favorites_provider.dart';
import 'presentation/providers/recents_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/root_tab_screen.dart';

/// Raíz de la app: registra los providers (equivalente a los
/// `.environmentObject(...)` de GestorArchivosApp.swift) y aplica el tema.
class GestorArchivosApp extends StatelessWidget {
  const GestorArchivosApp({
    super.key,
    required this.fileRepository,
    required this.preferencesRepository,
  });

  final FileRepository fileRepository;
  final PreferencesRepository preferencesRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FileRepository>.value(value: fileRepository),
        Provider<PreferencesRepository>.value(value: preferencesRepository),
        ChangeNotifierProvider(create: (_) => SettingsProvider(preferencesRepository)),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(preferencesRepository, fileRepository)..refresh(),
        ),
        ChangeNotifierProvider(
          create: (_) => RecentsProvider(preferencesRepository, fileRepository)..refresh(),
        ),
      ],
      // Solo se reconstruye MaterialApp cuando cambia el tema o el modo.
      child: Selector<SettingsProvider, (AppThemeOption, AppearanceMode)>(
        selector: (_, settings) => (settings.theme, settings.appearance),
        builder: (context, value, _) {
          final (theme, appearance) = value;
          return MaterialApp(
            title: 'Gestor de Archivos',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(theme),
            darkTheme: AppTheme.dark(theme),
            themeMode: appearance.themeMode,
            locale: const Locale('es', 'MX'),
            supportedLocales: const [Locale('es', 'MX'), Locale('es'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const RootTabScreen(),
          );
        },
      ),
    );
  }
}

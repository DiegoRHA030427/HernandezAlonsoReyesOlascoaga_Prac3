import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../providers/recents_provider.dart';
import 'favorites_screen.dart';
import 'locations_screen.dart';
import 'recents_screen.dart';
import 'settings_screen.dart';

/// Punto de entrada de la interfaz: pestañas Archivos / Favoritos / Recientes /
/// Ajustes (igual que RootTabView.swift). Cada pestaña tiene su propio Navigator,
/// como un NavigationStack por pestaña, para que la barra inferior no desaparezca.
class RootTabScreen extends StatefulWidget {
  const RootTabScreen({super.key});

  @override
  State<RootTabScreen> createState() => _RootTabScreenState();
}

class _RootTabScreenState extends State<RootTabScreen> {
  int _index = 0;
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: 'Archivos',
    ),
    NavigationDestination(
      icon: Icon(Icons.star_outline),
      selectedIcon: Icon(Icons.star),
      label: 'Favoritos',
    ),
    NavigationDestination(
      icon: Icon(Icons.history),
      label: 'Recientes',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Ajustes',
    ),
  ];

  Widget _rootFor(int index) => switch (index) {
        0 => const LocationsScreen(),
        1 => const FavoritesScreen(),
        2 => const RecentsScreen(),
        _ => const SettingsScreen(),
      };

  void _onSelect(int index) {
    if (index == _index) {
      // Tocar la pestaña activa regresa a su pantalla raíz.
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    if (index == 1) context.read<FavoritesProvider>().refresh();
    if (index == 2) context.read<RecentsProvider>().refresh();
    setState(() => _index = index);
  }

  /// Botón "atrás" de Android: primero regresa dentro de la pestaña actual.
  Future<void> _handleBack() async {
    final navigator = _navigatorKeys[_index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _destinations.length; i++)
              Navigator(
                key: _navigatorKeys[i],
                onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => _rootFor(i),
                ),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _onSelect,
          destinations: _destinations,
        ),
      ),
    );
  }
}

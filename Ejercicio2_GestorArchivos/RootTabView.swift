import SwiftUI

/// Punto de entrada de la interfaz: pestañas Archivos / Favoritos / Recientes / Ajustes.
struct RootTabView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        TabView {
            NavigationStack {
                LocationsListView()
            }
            .tabItem { Label("Archivos", systemImage: "folder") }

            NavigationStack {
                FavoritesView()
            }
            .tabItem { Label("Favoritos", systemImage: "star") }

            NavigationStack {
                RecentsView()
            }
            .tabItem { Label("Recientes", systemImage: "clock") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(settings.theme.accentColor)
    }
}

/// Pantalla raíz: los tres directorios accesibles del sandbox (2.1).
struct LocationsListView: View {
    private let locations = FileSystemService.shared.rootLocations

    var body: some View {
        List(locations, id: \.url) { location in
            NavigationLink(destination: FileBrowserView(directory: location.url, title: location.name)) {
                Label(location.name, systemImage: iconName(for: location.name))
            }
        }
        .navigationTitle("Gestor de Archivos")
    }

    private func iconName(for name: String) -> String {
        if name.hasPrefix("Documents") { return "doc.on.doc" }
        if name.hasPrefix("Inbox") { return "tray.and.arrow.down" }
        return "clock.arrow.circlepath"
    }
}

struct FavoritesView: View {
    @EnvironmentObject var favorites: FavoritesStore

    var body: some View {
        List {
            if favorites.items.isEmpty {
                ContentUnavailableFallback(message: "No tienes archivos favoritos todavía.\nMantén presionado un archivo y elige \"Agregar a favoritos\".")
            } else {
                ForEach(favorites.items) { item in
                    FileRowView(item: item, isFavorite: true)
                }
                .onDelete(perform: favorites.remove)
            }
        }
        .navigationTitle("Favoritos")
    }
}

struct RecentsView: View {
    @EnvironmentObject var recents: RecentsStore

    var body: some View {
        List {
            if recents.items.isEmpty {
                ContentUnavailableFallback(message: "Aún no has abierto archivos.")
            } else {
                ForEach(recents.items) { item in
                    FileRowView(item: item, isFavorite: false)
                }
            }
        }
        .navigationTitle("Recientes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Limpiar") { recents.clear() }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        Form {
            Section("Tema") {
                Picker("Tema", selection: $settings.theme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section("Preferencias de sesión") {
                LabeledContent("Última carpeta visitada",
                                value: settings.lastVisitedPath.isEmpty ? "—" : (settings.lastVisitedPath as NSString).lastPathComponent)
            }
            Section("Acerca de") {
                Text("Gestor de Archivos — Práctica 3, Ejercicio 2")
                Text("IPN · ESCOM — Desarrollo de aplicaciones móviles nativas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ajustes")
    }
}

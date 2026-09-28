import SwiftUI

@main
struct GestorArchivosApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var recents = RecentsStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
                .environmentObject(favorites)
                .environmentObject(recents)
                .tint(settings.theme.accentColor)
                .preferredColorScheme(nil) // respeta el modo claro/oscuro del sistema
        }
    }
}

import SwiftUI
import CoreData

@main
struct CamaraMicrofonoApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settings)
                .tint(settings.theme.accentColor)
        }
    }
}

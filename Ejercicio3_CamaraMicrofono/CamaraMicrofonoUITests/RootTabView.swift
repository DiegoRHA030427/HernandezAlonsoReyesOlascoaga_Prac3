import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        TabView {
            CameraCaptureView()
                .tabItem { Label("Cámara", systemImage: "camera") }

            AudioRecorderView()
                .tabItem { Label("Audio", systemImage: "mic") }

            GalleryView()
                .tabItem { Label("Galería", systemImage: "photo.on.rectangle") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
        .tint(settings.theme.accentColor)
    }
}

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Tema") {
                    Picker("Tema", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Preferencias") {
                    TextField("Álbum por defecto", text: $settings.defaultAlbum)
                }
                Section("Acerca de") {
                    Text("Cámara y Micrófono — Práctica 3, Ejercicio 3")
                    Text("IPN · ESCOM — Desarrollo de aplicaciones móviles nativas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}

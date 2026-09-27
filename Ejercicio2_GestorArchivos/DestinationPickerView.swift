import SwiftUI

/// Mini navegador de carpetas para elegir destino al copiar/mover un archivo (2.1).
struct DestinationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let startDirectory: URL
    let title: String
    let onSelect: (URL) -> Void

    @State private var items: [FileSystemItem] = []

    init(startDirectory: URL, title: String = "Elegir carpeta", onSelect: @escaping (URL) -> Void) {
        self.startDirectory = startDirectory
        self.title = title
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(items.filter(\.isDirectory)) { folder in
                    NavigationLink(folder.name) {
                        DestinationPickerView(startDirectory: folder.url, title: folder.name, onSelect: onSelect)
                    }
                }
            }
            .overlay {
                if items.filter(\.isDirectory).isEmpty {
                    ContentUnavailableFallback(message: "No hay subcarpetas aquí.\nPuedes elegir esta carpeta con el botón de arriba.")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Elegir esta carpeta") {
                        onSelect(startDirectory)
                        dismiss()
                    }
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        items = (try? FileSystemService.shared.contents(of: startDirectory)) ?? []
    }
}

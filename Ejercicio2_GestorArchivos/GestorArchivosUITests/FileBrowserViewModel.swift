import SwiftUI

/// Lógica de una carpeta: listar, buscar, ordenar y ejecutar las acciones de
/// archivo (crear, renombrar, eliminar, copiar, mover, importar) del 2.1.
@MainActor
final class FileBrowserViewModel: ObservableObject {
    let currentDirectory: URL

    @Published var items: [FileSystemItem] = []
    @Published var searchText: String = ""
    @Published var sortOption: SortOption = .name
    @Published var errorMessage: String?

    private let service = FileSystemService.shared

    init(startDirectory: URL) {
        self.currentDirectory = startDirectory
    }

    /// Resultado visible tras aplicar búsqueda (2.2) y ordenamiento (2.2).
    var displayedItems: [FileSystemItem] {
        let filtered = searchText.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }

        switch sortOption {
        case .name:
            return filtered.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .date:
            return filtered.sorted { $0.modificationDate > $1.modificationDate }
        case .size:
            return filtered.sorted { $0.size > $1.size }
        }
    }

    func load() {
        do {
            items = try service.contents(of: currentDirectory)
        } catch {
            errorMessage = "No se pudo leer la carpeta: \(error.localizedDescription)"
            items = []
        }
    }

    func createFolder(named name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try service.createFolder(named: name, in: currentDirectory)
            load()
        } catch {
            errorMessage = "No se pudo crear la carpeta: \(error.localizedDescription)"
        }
    }

    func delete(_ item: FileSystemItem) {
        do {
            try service.delete(item)
            load()
        } catch {
            errorMessage = "No se pudo eliminar \"\(item.name)\": \(error.localizedDescription)"
        }
    }

    func rename(_ item: FileSystemItem, to newName: String) {
        guard !newName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            try service.rename(item, to: newName)
            load()
        } catch {
            errorMessage = "No se pudo renombrar: \(error.localizedDescription)"
        }
    }

    /// Copia rápida dentro de la misma carpeta ("Duplicar").
    func duplicate(_ item: FileSystemItem) {
        do {
            try service.copy(item, to: currentDirectory)
            load()
        } catch {
            errorMessage = "No se pudo duplicar: \(error.localizedDescription)"
        }
    }

    /// Copia hacia una carpeta destino elegida en DestinationPickerView.
    func copy(_ item: FileSystemItem, to destination: URL) {
        do {
            try service.copy(item, to: destination)
            if destination == currentDirectory { load() }
        } catch {
            errorMessage = "No se pudo copiar: \(error.localizedDescription)"
        }
    }

    func move(_ item: FileSystemItem, to destination: URL) {
        do {
            try service.move(item, to: destination)
            load()
        } catch {
            errorMessage = "No se pudo mover: \(error.localizedDescription)"
        }
    }

    func importFile(from url: URL) {
        do {
            try service.importFile(from: url, to: currentDirectory)
            load()
        } catch {
            errorMessage = "No se pudo importar el archivo: \(error.localizedDescription)"
        }
    }
}

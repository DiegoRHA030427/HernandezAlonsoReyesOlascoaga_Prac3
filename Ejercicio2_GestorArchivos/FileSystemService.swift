import Foundation

/// Envuelve todas las operaciones de FileManager que pide el 2.1:
/// explorar, crear carpetas, copiar, mover, renombrar, eliminar e importar.
/// Solo trabaja dentro del sandbox de la app (2.4: nunca rutas fuera del contenedor).
final class FileSystemService {
    static let shared = FileSystemService()
    private let fm = FileManager.default

    var documentsURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// iOS entrega aquí los archivos recibidos por "Abrir en..." cuando la app
    /// no declara un tipo de documento propio. La creamos si no existe todavía
    /// para poder explorarla desde el primer arranque.
    var inboxURL: URL {
        let inbox = documentsURL.appendingPathComponent("Inbox", isDirectory: true)
        if !fm.fileExists(atPath: inbox.path) {
            try? fm.createDirectory(at: inbox, withIntermediateDirectories: true)
        }
        return inbox
    }

    var tmpURL: URL { fm.temporaryDirectory }

    /// Los tres directorios accesibles que pide el enunciado (2.1).
    var rootLocations: [(name: String, url: URL)] {
        [("Documents", documentsURL), ("Inbox", inboxURL), ("Temporal (tmp)", tmpURL)]
    }

    func contents(of directory: URL) throws -> [FileSystemItem] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey]
        let urls = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles])
        return urls.map(FileSystemItem.init)
    }

    func createFolder(named name: String, in directory: URL) throws {
        let target = directory.appendingPathComponent(name, isDirectory: true)
        try fm.createDirectory(at: target, withIntermediateDirectories: false)
    }

    func delete(_ item: FileSystemItem) throws {
        try fm.removeItem(at: item.url)
    }

    @discardableResult
    func rename(_ item: FileSystemItem, to newName: String) throws -> URL {
        let newURL = item.url.deletingLastPathComponent().appendingPathComponent(newName)
        try fm.moveItem(at: item.url, to: newURL)
        return newURL
    }

    /// Copia dentro del mismo directorio (usado para "Duplicar") o hacia otro destino.
    func copy(_ item: FileSystemItem, to destinationDirectory: URL) throws {
        let target = uniqueDestination(for: item.url.lastPathComponent, in: destinationDirectory)
        try fm.copyItem(at: item.url, to: target)
    }

    func move(_ item: FileSystemItem, to destinationDirectory: URL) throws {
        let target = uniqueDestination(for: item.url.lastPathComponent, in: destinationDirectory)
        try fm.moveItem(at: item.url, to: target)
    }

    /// Copia un archivo externo (elegido con UIDocumentPickerViewController) al directorio actual.
    @discardableResult
    func importFile(from sourceURL: URL, to directory: URL) throws -> URL {
        let target = uniqueDestination(for: sourceURL.lastPathComponent, in: directory)
        try fm.copyItem(at: sourceURL, to: target)
        return target
    }

    /// Evita sobrescribir archivos con el mismo nombre agregando "(1)", "(2)", etc.
    private func uniqueDestination(for name: String, in directory: URL) -> URL {
        var candidate = directory.appendingPathComponent(name)
        var counter = 1
        let baseName = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        while fm.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(baseName) (\(counter))" : "\(baseName) (\(counter)).\(ext)"
            candidate = directory.appendingPathComponent(newName)
            counter += 1
        }
        return candidate
    }
}

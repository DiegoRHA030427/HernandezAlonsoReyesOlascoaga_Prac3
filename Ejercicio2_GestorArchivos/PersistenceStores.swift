import UIKit

// MARK: - Favoritos (2.3: "sistema de favoritos persistente")

final class FavoritesStore: ObservableObject {
    @Published private(set) var paths: [String] = []
    private let key = "favoritePaths"

    init() {
        paths = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func contains(_ url: URL) -> Bool { paths.contains(url.path) }

    func toggle(_ url: URL) {
        if let idx = paths.firstIndex(of: url.path) {
            paths.remove(at: idx)
        } else {
            paths.append(url.path)
        }
        persist()
    }

    func remove(at offsets: IndexSet) {
        paths.remove(atOffsets: offsets)
        persist()
    }

    var items: [FileSystemItem] {
        paths.compactMap { path in
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            return FileSystemItem(url: URL(fileURLWithPath: path))
        }
    }

    private func persist() {
        UserDefaults.standard.set(paths, forKey: key)
    }
}

// MARK: - Recientes (2.3: "historial de archivos recientes")

final class RecentsStore: ObservableObject {
    @Published private(set) var paths: [String] = []
    private let key = "recentPaths"
    private let limit = 25

    init() {
        paths = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(_ url: URL) {
        paths.removeAll { $0 == url.path }
        paths.insert(url.path, at: 0)
        if paths.count > limit { paths = Array(paths.prefix(limit)) }
        persist()
    }

    func clear() {
        paths.removeAll()
        persist()
    }

    var items: [FileSystemItem] {
        paths.compactMap { path in
            guard FileManager.default.fileExists(atPath: path) else { return nil }
            return FileSystemItem(url: URL(fileURLWithPath: path))
        }
    }

    private func persist() {
        UserDefaults.standard.set(paths, forKey: key)
    }
}

// MARK: - Caché de miniaturas (2.3: "gestionar caché para miniaturas de imágenes")

final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(for item: FileSystemItem, targetSize: CGSize = CGSize(width: 80, height: 80)) -> UIImage? {
        guard item.isImageFile else { return nil }
        let key = "\(item.url.path)-\(item.modificationDate.timeIntervalSince1970)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let data = try? Data(contentsOf: item.url), let image = UIImage(data: data) else { return nil }
        let thumbnail = image.preparingThumbnail(of: targetSize) ?? image
        cache.setObject(thumbnail, forKey: key)
        return thumbnail
    }
}

// MARK: - Bookmarks de seguridad (2.4: "conservar permisos con security-scoped bookmarks")
//
// Se usan cuando el usuario quiere referenciar un archivo EXTERNO (por ejemplo,
// en iCloud Drive) sin copiarlo al sandbox. UIDocumentPickerViewController se abre
// con asCopy:false, y aquí guardamos un bookmark para poder volver a acceder a
// ese archivo en sesiones futuras respetando el sandbox de iOS.

struct ExternalBookmark: Identifiable, Codable {
    let id: String
    let displayName: String
}

final class SecurityScopedBookmarkStore {
    static let shared = SecurityScopedBookmarkStore()
    private let key = "externalBookmarks.v1"

    private var raw: [String: Data] {
        get { (UserDefaults.standard.dictionary(forKey: key) as? [String: Data]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    @discardableResult
    func save(url: URL) throws -> ExternalBookmark {
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "GestorArchivos", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener acceso al archivo externo."])
        }
        defer { url.stopAccessingSecurityScopedResource() }

        let data = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        let id = UUID().uuidString
        var current = raw
        current[id] = data
        raw = current
        return ExternalBookmark(id: id, displayName: url.lastPathComponent)
    }

    /// Resuelve el bookmark y, si sigue siendo válido, entrega una URL que ya
    /// puede leerse (recuerda envolver el acceso real en start/stopAccessingSecurityScopedResource).
    func resolve(_ bookmark: ExternalBookmark) -> URL? {
        guard let data = raw[bookmark.id] else { return nil }
        var isStale = false
        guard let url = try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        return url
    }

    func remove(_ bookmark: ExternalBookmark) {
        var current = raw
        current.removeValue(forKey: bookmark.id)
        raw = current
    }
}

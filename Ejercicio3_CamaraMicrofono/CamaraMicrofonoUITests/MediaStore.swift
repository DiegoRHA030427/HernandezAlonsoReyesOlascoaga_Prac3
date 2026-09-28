import UIKit
import CoreData

/// Tipo de contenido capturado, guardado como String en el atributo `type` de CapturedItem.
enum MediaType: String {
    case photo
    case audio
}

/// Centraliza el guardado físico de archivos (3.5: "Guardar todos los archivos capturados en
/// el almacenamiento del dispositivo") y su registro de metadatos en Core Data
/// (3.5: "Implementar Core Data para metadatos: fecha, ubicación, etiquetas").
final class MediaStore {
    static let shared = MediaStore()
    private let fm = FileManager.default

    /// Carpeta dentro de Documents donde viven las fotos y los audios capturados.
    var mediaDirectory: URL {
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Capturas", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func url(for fileName: String) -> URL {
        mediaDirectory.appendingPathComponent(fileName)
    }

    // MARK: - Guardar foto

    @discardableResult
    func savePhoto(_ image: UIImage,
                   album: String,
                   location: (lat: Double, lon: Double)?,
                   context: NSManagedObjectContext) -> CapturedItem? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let fileName = "IMG_\(Int(Date().timeIntervalSince1970 * 1000)).jpg"
        let destination = url(for: fileName)
        do {
            try data.write(to: destination)
        } catch {
            print("No se pudo guardar la foto: \(error)")
            return nil
        }
        return makeItem(type: .photo, fileName: fileName, album: album, duration: 0, location: location, context: context)
    }

    /// Sobrescribe el archivo de una foto ya existente (usado por la edición básica: rotar/filtro).
    func overwritePhoto(_ image: UIImage, fileName: String) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: url(for: fileName))
    }

    // MARK: - Guardar audio

    @discardableResult
    func saveAudio(temporaryURL: URL,
                   duration: TimeInterval,
                   album: String,
                   context: NSManagedObjectContext) -> CapturedItem? {
        let fileName = "REC_\(Int(Date().timeIntervalSince1970 * 1000)).m4a"
        let destination = url(for: fileName)
        do {
            if fm.fileExists(atPath: destination.path) {
                try fm.removeItem(at: destination)
            }
            try fm.moveItem(at: temporaryURL, to: destination)
        } catch {
            print("No se pudo guardar el audio: \(error)")
            return nil
        }
        return makeItem(type: .audio, fileName: fileName, album: album, duration: duration, location: nil, context: context)
    }

    // MARK: - Core Data

    private func makeItem(type: MediaType,
                           fileName: String,
                           album: String,
                           duration: TimeInterval,
                           location: (lat: Double, lon: Double)?,
                           context: NSManagedObjectContext) -> CapturedItem {
        let item = CapturedItem(context: context)
        item.id = UUID()
        item.type = type.rawValue
        item.fileName = fileName
        item.dateCreated = Date()
        item.albumName = album.isEmpty ? "General" : album
        item.tags = ""
        item.isFavorite = false
        item.duration = duration
        if let location {
            item.latitude = location.lat
            item.longitude = location.lon
            item.hasLocation = true
        } else {
            item.hasLocation = false
        }
        PersistenceController.shared.save()
        return item
    }

    func delete(_ item: CapturedItem, context: NSManagedObjectContext) {
        if let fileName = item.fileName {
            try? fm.removeItem(at: url(for: fileName))
        }
        context.delete(item)
        PersistenceController.shared.save()
    }

    /// Nombres de álbum existentes, para el picker de "organizar en categorías" (3.3).
    func existingAlbums(context: NSManagedObjectContext) -> [String] {
        let request: NSFetchRequest<CapturedItem> = CapturedItem.fetchRequest()
        let items = (try? context.fetch(request)) ?? []
        var names = Set(items.compactMap { $0.albumName })
        names.insert("General")
        return names.sorted()
    }
}

// MARK: - Caché de miniaturas de fotos (3.5: "Mantener miniaturas y caché para acceso rápido a la galería")

final class MediaThumbnailCache {
    static let shared = MediaThumbnailCache()
    private let cache = NSCache<NSString, UIImage>()

    func thumbnail(fileName: String, targetSize: CGSize = CGSize(width: 160, height: 160)) -> UIImage? {
        let key = fileName as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let fileURL = MediaStore.shared.url(for: fileName)
        guard let data = try? Data(contentsOf: fileURL), let image = UIImage(data: data) else { return nil }
        let thumbnail = image.preparingThumbnail(of: targetSize) ?? image
        cache.setObject(thumbnail, forKey: key)
        return thumbnail
    }

    func invalidate(fileName: String) {
        cache.removeObject(forKey: fileName as NSString)
    }
}

import Foundation
import UniformTypeIdentifiers

/// Representa un archivo o carpeta dentro del sandbox de la app.
struct FileSystemItem: Identifiable, Hashable {
    let url: URL
    let name: String
    let isDirectory: Bool
    let size: Int64
    let modificationDate: Date
    let contentType: UTType?

    var id: String { url.path }

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey
        ])
        self.isDirectory = values?.isDirectory ?? false
        self.size = Int64(values?.fileSize ?? 0)
        self.modificationDate = values?.contentModificationDate ?? .distantPast
        self.contentType = values?.contentType
    }

    /// Ícono según el tipo de archivo (UTType), como pide el 2.1.
    var systemImageName: String {
        if isDirectory { return "folder.fill" }
        guard let type = contentType else { return "doc" }
        if type.conforms(to: .image) { return "photo" }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return "film" }
        if type.conforms(to: .audio) { return "waveform" }
        if type.conforms(to: .pdf) { return "doc.richtext" }
        if type.conforms(to: .sourceCode) { return "chevron.left.forwardslash.chevron.right" }
        if type.conforms(to: .json) { return "curlybraces" }
        if type.conforms(to: .plainText) || type.conforms(to: .text) { return "doc.text" }
        if type.conforms(to: .archive) || type.conforms(to: .zip) { return "doc.zipper" }
        return "doc"
    }

    var isTextFile: Bool {
        if let type = contentType {
            return type.conforms(to: .text) || type.conforms(to: .sourceCode) || type.conforms(to: .json)
        }
        let textExtensions: Set<String> = ["txt", "md", "swift", "json", "csv", "log", "xml", "yaml", "yml"]
        return textExtensions.contains(url.pathExtension.lowercased())
    }

    var isImageFile: Bool {
        if let type = contentType { return type.conforms(to: .image) }
        let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "heic", "bmp", "webp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }
}

/// Criterios de ordenamiento (2.2: "ordenamiento por nombre, fecha o tamaño").
enum SortOption: String, CaseIterable, Identifiable {
    case name, date, size

    var id: String { rawValue }

    var label: String {
        switch self {
        case .name: return "Nombre"
        case .date: return "Fecha"
        case .size: return "Tamaño"
        }
    }
}

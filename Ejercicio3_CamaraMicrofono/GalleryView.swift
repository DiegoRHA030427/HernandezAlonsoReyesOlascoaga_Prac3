import SwiftUI
import CoreData

/// Galería integrada (3.3): fotos y audios capturados, organizables por álbum/categoría,
/// con miniaturas cacheadas para acceso rápido (3.5).
struct GalleryView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CapturedItem.dateCreated, ascending: false)]
    ) private var items: FetchedResults<CapturedItem>

    @State private var selectedAlbum: String = "Todos"
    @State private var selectedItem: CapturedItem?

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]

    private var albums: [String] {
        var names = Set(items.compactMap { $0.albumName })
        names.insert("General")
        return ["Todos"] + names.sorted()
    }

    private var filteredItems: [CapturedItem] {
        selectedAlbum == "Todos" ? Array(items) : items.filter { $0.albumName == selectedAlbum }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredItems.isEmpty {
                    ContentUnavailableFallback(message: "Todavía no has capturado fotos ni audios.\nUsa las pestañas Cámara o Audio para empezar.")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(filteredItems) { item in
                                Button { selectedItem = item } label: {
                                    GalleryCell(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle("Galería")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Picker("Álbum", selection: $selectedAlbum) {
                        ForEach(albums, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .sheet(item: $selectedItem) { item in
                if item.type == MediaType.audio.rawValue {
                    AudioPlayerView(item: item)
                } else {
                    PhotoDetailView(item: item)
                }
            }
        }
    }
}

// Nota: no se declara aquí una conformidad manual a Identifiable — Core Data ya la genera
// automáticamente para CapturedItem porque la entidad tiene un atributo llamado "id".

private struct GalleryCell: View {
    @ObservedObject var item: CapturedItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnail
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if item.isFavorite {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                    .padding(4)
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if item.type == MediaType.photo.rawValue,
           let fileName = item.fileName,
           let image = MediaThumbnailCache.shared.thumbnail(fileName: fileName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(.secondary.opacity(0.15))
                .overlay {
                    Image(systemName: item.type == MediaType.audio.rawValue ? "waveform" : "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

import SwiftUI
import CoreData

/// Visor de fotos con edición básica (3.3: "opciones básicas de edición"): rotar, aplicar un
/// filtro y volver a guardar; además favoritos, etiquetas, álbum, compartir y eliminar.
struct PhotoDetailView: View {
    @ObservedObject var item: CapturedItem
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var image: UIImage?
    @State private var tagsText: String = ""
    @State private var albumText: String = ""
    @State private var showingDeleteConfirm = false
    @State private var showingShareSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 360)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        ContentUnavailableFallback(message: "No se pudo cargar la imagen.")
                            .frame(height: 200)
                    }

                    HStack(spacing: 24) {
                        Button {
                            rotate()
                        } label: {
                            Label("Rotar", systemImage: "rotate.right")
                        }
                        Button {
                            item.isFavorite.toggle()
                            PersistenceController.shared.save()
                        } label: {
                            Label(item.isFavorite ? "Favorito" : "Marcar", systemImage: item.isFavorite ? "star.fill" : "star")
                        }
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Compartir", systemImage: "square.and.arrow.up")
                        }
                    }
                    .buttonStyle(.bordered)

                    HStack(spacing: 12) {
                        ForEach(PhotoFilter.allCases) { filter in
                            Button(filter.label) { applyFilter(filter) }
                                .buttonStyle(.bordered)
                                .font(.caption)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Álbum / categoría", text: $albumText, onCommit: saveMetadata)
                            .textFieldStyle(.roundedBorder)
                        TextField("Etiquetas (separadas por coma)", text: $tagsText, onCommit: saveMetadata)
                            .textFieldStyle(.roundedBorder)

                        if let date = item.dateCreated {
                            Text("Capturada el \(date.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if item.hasLocation {
                            Text("Ubicación: \(item.latitude, specifier: "%.4f"), \(item.longitude, specifier: "%.4f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { saveMetadata(); dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .alert("Eliminar foto", isPresented: $showingDeleteConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    MediaStore.shared.delete(item, context: context)
                    dismiss()
                }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image {
                    ShareSheet(items: [image])
                }
            }
            .onAppear {
                tagsText = item.tags ?? ""
                albumText = item.albumName ?? "General"
                loadImage()
            }
        }
    }

    private func loadImage() {
        guard let fileName = item.fileName else { return }
        if let data = try? Data(contentsOf: MediaStore.shared.url(for: fileName)) {
            image = UIImage(data: data)
        }
    }

    private func rotate() {
        guard let current = image, let cgImage = current.cgImage else { return }
        let rotated = UIImage(cgImage: cgImage, scale: current.scale,
                               orientation: nextOrientation(current.imageOrientation))
        image = rotated
        persistEdited(rotated)
    }

    private func nextOrientation(_ orientation: UIImage.Orientation) -> UIImage.Orientation {
        switch orientation {
        case .up: return .right
        case .right: return .down
        case .down: return .left
        default: return .up
        }
    }

    private func applyFilter(_ filter: PhotoFilter) {
        guard let current = image else { return }
        let filtered = filter.apply(to: current)
        image = filtered
        persistEdited(filtered)
    }

    private func persistEdited(_ newImage: UIImage) {
        guard let fileName = item.fileName else { return }
        MediaStore.shared.overwritePhoto(newImage, fileName: fileName)
        MediaThumbnailCache.shared.invalidate(fileName: fileName)
    }

    private func saveMetadata() {
        item.tags = tagsText
        item.albumName = albumText.isEmpty ? "General" : albumText
        PersistenceController.shared.save()
    }
}

/// Reutilizable: hoja de compartir del sistema (igual que en el Ejercicio 2).
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ContentUnavailableFallback: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

import SwiftUI

// MARK: - Visor de imágenes (2.1: zoom con pinza, rotación, ajuste a pantalla)

struct ImageViewerView: View {
    let item: FileSystemItem
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var uiImage: UIImage?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .rotationEffect(rotation)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .simultaneousGesture(rotationGesture)
                        .simultaneousGesture(dragGesture)
                        .onTapGesture(count: 2) { resetTransform() }
                } else {
                    ProgressView().tint(.white)
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        resetTransform()
                    } label: {
                        Image(systemName: "arrow.up.left.and.down.right.magnifyingglass")
                    }
                    .accessibilityLabel("Ajustar a pantalla")
                }
            }
        }
        .onAppear {
            if let data = try? Data(contentsOf: item.url) {
                uiImage = UIImage(data: data)
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in scale = lastScale * value }
            .onEnded { _ in lastScale = scale }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in rotation = lastRotation + value }
            .onEnded { _ in lastRotation = rotation }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width,
                                 height: lastOffset.height + value.translation.height)
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func resetTransform() {
        withAnimation {
            scale = 1; lastScale = 1
            rotation = .zero; lastRotation = .zero
            offset = .zero; lastOffset = .zero
        }
    }
}

// MARK: - Visor/editor de texto (2.1: abrir y visualizar .txt, .md, .swift, .json, etc.)

struct TextFileView: View {
    let item: FileSystemItem
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @State private var isEditing = false
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableFallback(message: loadError)
                } else if isEditing {
                    TextEditor(text: $text)
                        .font(.system(.body, design: .monospaced))
                        .padding(4)
                } else {
                    ScrollView {
                        Text(text)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Guardar") { save() }
                    } else {
                        Button("Editar") { isEditing = true }
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        do {
            text = try String(contentsOf: item.url, encoding: .utf8)
        } catch {
            loadError = "No se pudo leer el archivo como texto.\n\(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            try text.write(to: item.url, atomically: true, encoding: .utf8)
            isEditing = false
        } catch {
            loadError = "No se pudo guardar el archivo.\n\(error.localizedDescription)"
        }
    }
}

// MARK: - Mensaje de respaldo para errores (equivalente simple a ContentUnavailableView,
// que requiere iOS 17; aquí soportamos iOS 16).

struct ContentUnavailableFallback: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

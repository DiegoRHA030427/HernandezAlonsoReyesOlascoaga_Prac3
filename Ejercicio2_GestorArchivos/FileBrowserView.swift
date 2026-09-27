import SwiftUI

/// Vista principal de exploración (2.1 y 2.2): lista jerárquica, búsqueda,
/// ordenamiento, gestos (swipe, long-press, pull-to-refresh) y todas las
/// acciones de archivo.
struct FileBrowserView: View {
    let directory: URL
    let title: String

    @StateObject private var viewModel: FileBrowserViewModel
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var recents: RecentsStore

    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    @State private var showingDocumentPicker = false

    @State private var itemToRename: FileSystemItem?
    @State private var renameText = ""
    @State private var itemPendingDelete: FileSystemItem?

    @State private var selectedImageItem: FileSystemItem?
    @State private var selectedTextItem: FileSystemItem?
    @State private var quickLookItem: FileSystemItem?
    @State private var itemToShare: FileSystemItem?

    @State private var itemPendingMove: FileSystemItem?
    @State private var itemPendingCopy: FileSystemItem?
    @State private var showingMovePicker = false
    @State private var showingCopyPicker = false

    init(directory: URL, title: String? = nil) {
        self.directory = directory
        self.title = title ?? directory.lastPathComponent
        _viewModel = StateObject(wrappedValue: FileBrowserViewModel(startDirectory: directory))
    }

    var body: some View {
        List {
            ForEach(viewModel.displayedItems) { item in
                rowView(for: item)
            }
        }
        .listStyle(.plain)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Buscar en \(title)")
        .refreshable { viewModel.load() } // pull-to-refresh (2.2)
        .toolbar { toolbarContent }
        .onAppear {
            settings.lastVisitedPath = directory.path
            viewModel.load()
        }
        // Alertas de acciones
        .alert("Nueva carpeta", isPresented: $showingNewFolderAlert) {
            TextField("Nombre", text: $newFolderName)
            Button("Cancelar", role: .cancel) { newFolderName = "" }
            Button("Crear") {
                viewModel.createFolder(named: newFolderName)
                newFolderName = ""
            }
        }
        .alert("Renombrar", isPresented: Binding(
            get: { itemToRename != nil },
            set: { if !$0 { itemToRename = nil } }
        )) {
            TextField("Nuevo nombre", text: $renameText)
            Button("Cancelar", role: .cancel) { itemToRename = nil }
            Button("Guardar") {
                if let item = itemToRename { viewModel.rename(item, to: renameText) }
                itemToRename = nil
            }
        }
        .alert("Eliminar archivo", isPresented: Binding(
            get: { itemPendingDelete != nil },
            set: { if !$0 { itemPendingDelete = nil } }
        )) {
            Button("Cancelar", role: .cancel) {}
            Button("Eliminar", role: .destructive) {
                if let item = itemPendingDelete { viewModel.delete(item) }
            }
        } message: {
            Text("¿Seguro que quieres eliminar \"\(itemPendingDelete?.name ?? "")\"? Esta acción no se puede deshacer.")
        }
        .alert("Ocurrió un problema", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        // Importar (2.1)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker { url in viewModel.importFile(from: url) }
        }
        // Copiar / mover (2.1)
        .sheet(isPresented: $showingMovePicker) {
            DestinationPickerView(startDirectory: FileSystemService.shared.documentsURL, title: "Mover a...") { destination in
                if let item = itemPendingMove { viewModel.move(item, to: destination) }
            }
        }
        .sheet(isPresented: $showingCopyPicker) {
            DestinationPickerView(startDirectory: FileSystemService.shared.documentsURL, title: "Copiar a...") { destination in
                if let item = itemPendingCopy { viewModel.copy(item, to: destination) }
            }
        }
        // Visores (2.1)
        .fullScreenCover(item: $selectedImageItem) { item in
            ImageViewerView(item: item)
        }
        .sheet(item: $selectedTextItem) { item in
            TextFileView(item: item)
        }
        .sheet(item: $quickLookItem) { item in
            QuickLookPreview(url: item.url)
        }
        .sheet(item: $itemToShare) { item in
            ShareSheet(items: [item.url])
        }
    }

    @ViewBuilder
    private func rowView(for item: FileSystemItem) -> some View {
        Group {
            if item.isDirectory {
                NavigationLink(destination: FileBrowserView(directory: item.url)) {
                    FileRowView(item: item, isFavorite: favorites.contains(item.url))
                }
            } else {
                Button { openFile(item) } label: {
                    FileRowView(item: item, isFavorite: favorites.contains(item.url))
                }
                .buttonStyle(.plain)
            }
        }
        // Deslizar para eliminar / renombrar (2.2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { itemPendingDelete = item } label: {
                Label("Eliminar", systemImage: "trash")
            }
            Button { itemToRename = item; renameText = item.name } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            .tint(.orange)
        }
        .swipeActions(edge: .leading) {
            Button { favorites.toggle(item.url) } label: {
                Label(favorites.contains(item.url) ? "Quitar" : "Favorito", systemImage: "star")
            }
            .tint(.yellow)
        }
        // Mantener presionado para menú contextual (2.2)
        .contextMenu {
            Button { favorites.toggle(item.url) } label: {
                Label(favorites.contains(item.url) ? "Quitar de favoritos" : "Agregar a favoritos", systemImage: "star")
            }
            Button { itemToRename = item; renameText = item.name } label: {
                Label("Renombrar", systemImage: "pencil")
            }
            Button { viewModel.duplicate(item) } label: {
                Label("Duplicar", systemImage: "doc.on.doc")
            }
            Button { itemPendingCopy = item; showingCopyPicker = true } label: {
                Label("Copiar a...", systemImage: "folder")
            }
            if item.isDirectory == false {
                Button { itemPendingMove = item; showingMovePicker = true } label: {
                    Label("Mover a...", systemImage: "arrow.right.doc.on.clipboard")
                }
                Button { itemToShare = item } label: {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
            }
            Button(role: .destructive) { itemPendingDelete = item } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private func openFile(_ item: FileSystemItem) {
        recents.add(item.url)
        if item.isImageFile {
            selectedImageItem = item
        } else if item.isTextFile {
            selectedTextItem = item
        } else {
            quickLookItem = item
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Menu {
                Picker("Ordenar por", selection: $viewModel.sortOption) {
                    ForEach(SortOption.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            Button { showingDocumentPicker = true } label: {
                Image(systemName: "square.and.arrow.down")
            }
            .accessibilityLabel("Importar archivo")
            Button { showingNewFolderAlert = true } label: {
                Image(systemName: "folder.badge.plus")
            }
            .accessibilityLabel("Nueva carpeta")
        }
    }
}

import SwiftUI
import AVFoundation
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreData

/// Filtros básicos de captura (3.2: "Para fotos: filtros, flash, temporizador").
enum PhotoFilter: String, CaseIterable, Identifiable {
    case ninguno, sepia, blancoYNegro, vivido

    var id: String { rawValue }
    var label: String {
        switch self {
        case .ninguno: return "Ninguno"
        case .sepia: return "Sepia"
        case .blancoYNegro: return "Blanco y negro"
        case .vivido: return "Vívido"
        }
    }

    func apply(to image: UIImage) -> UIImage {
        guard self != .ninguno, let ciImage = CIImage(image: image) else { return image }
        let context = CIContext()
        let output: CIImage?
        switch self {
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = ciImage
            filter.intensity = 0.85
            output = filter.outputImage
        case .blancoYNegro:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .vivido:
            let filter = CIFilter.vibrance()
            filter.inputImage = ciImage
            filter.amount = 1.0
            output = filter.outputImage
        case .ninguno:
            output = ciImage
        }
        guard let output, let cgImage = context.createCGImage(output, from: ciImage.extent) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// Controla la sesión de captura con AVFoundation (3.2 y 3.6: "AVFoundation (AVCaptureSession)").
/// El simulador de iOS no tiene cámara física; `isCameraAvailable` queda en `false` ahí y la
/// interfaz ofrece como alternativa documentada el selector de fototeca (PHPickerViewController),
/// tal como permite el punto 3.2 del enunciado.
@MainActor
final class CameraModel: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isCameraAvailable = false
    @Published var flashOn = false
    @Published var filter: PhotoFilter = .ninguno
    @Published var timerSeconds: Int = 0 // 0 = sin temporizador
    @Published var countdown: Int?

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var onCapture: ((UIImage) -> Void)?
    private var countdownTimer: Timer?

    func configureIfNeeded() {
        isCameraAvailable = AVCaptureDevice.default(for: .video) != nil
        guard isCameraAvailable else { return }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted { self?.setupSession() }
                }
            }
        default:
            isAuthorized = false
        }
    }

    private func setupSession() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
        }
    }

    func stop() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [session] in
                session.stopRunning()
            }
        }
    }

    /// Dispara la captura respetando el temporizador configurado (3.2: "temporizador").
    func capturePhoto(completion: @escaping (UIImage) -> Void) {
        onCapture = completion
        guard timerSeconds > 0 else {
            performCapture()
            return
        }
        countdown = timerSeconds
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if let remaining = self.countdown, remaining > 1 {
                    self.countdown = remaining - 1
                } else {
                    self.countdown = nil
                    self.countdownTimer?.invalidate()
                    self.performCapture()
                }
            }
        }
    }

    private func performCapture() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashOn ? .on : .off
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                  didFinishProcessingPhoto photo: AVCapturePhoto,
                                  error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        Task { @MainActor in
            let filtered = self.filter.apply(to: image)
            self.onCapture?(filtered)
        }
    }
}

/// Envuelve la capa de previsualización de AVFoundation para usarla dentro de SwiftUI.
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

/// Selector de fototeca (alternativa a la cámara física, válida para probar en el simulador).
/// Si una foto en particular no se puede cargar (por ejemplo por un problema del servicio de
/// Fotos al convertirla), se avisa mediante `onFailure` en vez de dejar que la app truene, para
/// que puedas intentar con otra foto.
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    var onFailure: () -> Void = {}

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onFailure: onFailure) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (UIImage) -> Void
        let onFailure: () -> Void
        init(onPick: @escaping (UIImage) -> Void, onFailure: @escaping () -> Void) {
            self.onPick = onPick
            self.onFailure = onFailure
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                if !results.isEmpty { onFailure() }
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, error in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self.onPick(image)
                    } else {
                        self.onFailure()
                    }
                }
            }
        }
    }
}

/// Pantalla principal de captura de fotos (3.2, 3.4).
struct CameraCaptureView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var model = CameraModel()

    @State private var showingLibraryPicker = false
    @State private var previewImage: UIImage?
    @State private var showingSaveSheet = false
    @State private var libraryErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                if model.isCameraAvailable {
                    if model.isAuthorized {
                        CameraPreviewView(session: model.session)
                            .ignoresSafeArea()
                    } else {
                        permissionMessage("Se necesita acceso a la cámara. Ve a Ajustes del sistema y actívalo para GestorMultimedia.")
                    }
                } else {
                    // Alternativa documentada para el simulador de iOS (no tiene cámara física).
                    VStack(spacing: 16) {
                        Image(systemName: "camera.metering.unknown")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Este simulador no tiene cámara física.\nElige una foto de la fototeca como alternativa.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        if let libraryErrorMessage {
                            Text(libraryErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                        }
                        Button("Elegir de la fototeca") { showingLibraryPicker = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }

                if let countdown = model.countdown {
                    Text("\(countdown)")
                        .font(.system(size: 96, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                }

                VStack {
                    Spacer()
                    controlsBar
                }
            }
            .navigationTitle("Cámara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.isCameraAvailable && model.isAuthorized {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            model.flashOn.toggle()
                        } label: {
                            Image(systemName: model.flashOn ? "bolt.fill" : "bolt.slash")
                        }
                    }
                }
            }
            .onAppear { model.configureIfNeeded() }
            .onDisappear { model.stop() }
            .sheet(isPresented: $showingLibraryPicker) {
                PhotoLibraryPicker(onPick: { image in
                    libraryErrorMessage = nil
                    previewImage = image
                    showingSaveSheet = true
                }, onFailure: {
                    libraryErrorMessage = "No se pudo cargar esa foto. Intenta con otra (por ejemplo, una de las fotos de ejemplo que ya trae el simulador)."
                })
            }
            .sheet(isPresented: $showingSaveSheet) {
                if let previewImage {
                    SaveCapturedPhotoSheet(image: previewImage) { album in
                        finishSaving(previewImage, album: album)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var controlsBar: some View {
        if model.isCameraAvailable && model.isAuthorized {
            VStack(spacing: 12) {
                HStack {
                    Picker("Filtro", selection: $model.filter) {
                        ForEach(PhotoFilter.allCases) { f in Text(f.label).tag(f) }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)

                    Spacer()

                    Picker("Temporizador", selection: $model.timerSeconds) {
                        Text("Sin temporizador").tag(0)
                        Text("3 s").tag(3)
                        Text("5 s").tag(5)
                        Text("10 s").tag(10)
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }
                .padding(.horizontal)

                Button {
                    model.capturePhoto { image in
                        previewImage = image
                        showingSaveSheet = true
                    }
                } label: {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 72, height: 72)
                }
                .padding(.bottom, 24)
            }
            .background(.black.opacity(0.35))
        }
    }

    private func permissionMessage(_ text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.camera")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(text)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    private func finishSaving(_ image: UIImage, album: String) {
        LocationHelper.shared.requestOneShotLocation { location in
            MediaStore.shared.savePhoto(image, album: album, location: location, context: context)
            previewImage = nil
        }
    }
}

/// Hoja simple para confirmar en qué álbum guardar la foto recién capturada (3.3).
struct SaveCapturedPhotoSheet: View {
    let image: UIImage
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var album: String = "General"

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                TextField("Álbum / categoría", text: $album)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Guardar foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Descartar", role: .destructive) { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        onSave(album)
                        dismiss()
                    }
                }
            }
        }
    }
}

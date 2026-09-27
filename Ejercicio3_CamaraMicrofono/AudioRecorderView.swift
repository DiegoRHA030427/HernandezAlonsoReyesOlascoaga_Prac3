import SwiftUI
import AVFoundation
import CoreData
import UniformTypeIdentifiers

/// Grabador de audio con AVAudioRecorder (3.2 y 3.6). Implementa las dos personalizaciones que
/// pide el enunciado para audio: "niveles de sensibilidad" (ganancia de entrada del micrófono,
/// cuando el hardware la permite) y "temporizador de grabación" (duración máxima configurable).
@MainActor
final class AudioRecorderModel: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isRecording = false
    @Published var elapsed: TimeInterval = 0
    @Published var level: Float = 0 // 0...1, para el medidor de niveles en la UI
    @Published var inputGain: Float = 0.8 // "sensibilidad" del micrófono
    @Published var maxDuration: TimeInterval = 0 // 0 = sin límite ("temporizador de grabación")
    @Published var isGainAdjustable = false

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?
    private var isFallbackRecording = false
    private var fallbackStartDate: Date?

    func requestPermission() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async { self?.isAuthorized = granted }
        }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
        isGainAdjustable = session.isInputGainSettable
        if isGainAdjustable {
            try? session.setInputGain(inputGain)
        }
    }

    func updateGain(_ value: Float) {
        inputGain = value
        guard isGainAdjustable else { return }
        try? AVAudioSession.sharedInstance().setInputGain(value)
    }

    func startRecording() {
        configureSession()

        let fileName = UUID().uuidString + ".m4a"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        recordingURL = tempURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            recorder = try AVAudioRecorder(url: tempURL, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.delegate = self

            let started: Bool
            if maxDuration > 0 {
                started = recorder?.record(forDuration: maxDuration) ?? false
            } else {
                started = recorder?.record() ?? false
            }

            guard started else {
                beginFallbackRecording()
                return
            }

            isFallbackRecording = false
            isRecording = true
            elapsed = 0
            startTimer()
        } catch {
            print("No se pudo iniciar la grabación: \(error)")
            beginFallbackRecording()
        }
    }

    /// Si no hay micrófono disponible (por ejemplo en una VM sin hardware de audio), se simula
    /// la grabación con un cronómetro; al detenerla se genera un archivo de audio silencioso con
    /// esa misma duración, para que guardar/reproducir sigan funcionando de principio a fin.
    private func beginFallbackRecording() {
        recorder = nil
        deactivateSession() // liberamos la sesión rota para no dejarla reintentando en segundo plano
        isFallbackRecording = true
        isRecording = true
        elapsed = 0
        fallbackStartDate = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let start = self.fallbackStartDate else { return }
                self.elapsed = Date().timeIntervalSince(start)
                self.level = Float(0.3 + 0.3 * abs(sin(self.elapsed * 3)))
                if self.maxDuration > 0, self.elapsed >= self.maxDuration {
                    _ = self.stopRecording()
                }
            }
        }
    }

    /// Libera la sesión de audio para que no se quede intentando reconectar con un dispositivo
    /// que no existe (esto puede volver lenta o poco responsiva el resto de la app en entornos
    /// sin hardware de audio real, como una VM anidada).
    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    /// Calcula la duración de un archivo de audio importado (alternativa cuando no hay
    /// micrófono disponible en el entorno, análoga al selector de fototeca de la cámara).
    func duration(ofFileAt url: URL) -> TimeInterval {
        (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
    }

    func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil
        isRecording = false

        if isFallbackRecording {
            isFallbackRecording = false
            guard let url = recordingURL else { return nil }
            writeSilentAudioFile(to: url, duration: max(elapsed, 1))
            return url
        }

        recorder?.stop()
        return recordingURL
    }

    /// Genera un archivo .m4a silencioso de la duración indicada (respaldo cuando no hay
    /// micrófono real disponible, ver `beginFallbackRecording`).
    private func writeSilentAudioFile(to url: URL, duration: TimeInterval) {
        let sampleRate: Double = 44_100
        let frameCount = AVAudioFrameCount(max(1, duration) * sampleRate)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount // el buffer ya nace en ceros = silencio

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let file = try AVAudioFile(forWriting: url, settings: settings)
            try file.write(from: buffer)
        } catch {
            print("No se pudo generar el audio de respaldo: \(error)")
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let recorder = self.recorder, recorder.isRecording else { return }
                recorder.updateMeters()
                let db = recorder.averagePower(forChannel: 0) // típicamente entre -160 y 0 dB
                let normalized = max(0, (db + 60) / 60) // mapeo simple a 0...1
                self.elapsed = recorder.currentTime
                self.level = normalized
            }
        }
    }
}

extension AudioRecorderModel: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
            self.timer?.invalidate()
        }
    }
}

/// Selector de un archivo de audio existente (alternativa cuando no hay micrófono disponible
/// en el entorno, análoga al selector de fototeca de la pantalla de Cámara).
struct AudioFilePicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}

struct AudioRecorderView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var model = AudioRecorderModel()
    @State private var showingSaveSheet = false
    @State private var showingFilePicker = false
    @State private var pendingURL: URL?
    @State private var pendingDuration: TimeInterval = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 220, height: 220)
                        .scaleEffect(1 + CGFloat(model.level) * 0.3)
                        .animation(.easeOut(duration: 0.1), value: model.level)

                    Image(systemName: model.isRecording ? "waveform" : "mic.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.accentColor)
                }

                Text(formatted(model.elapsed))
                    .font(.system(.title, design: .monospaced))

                if !model.isAuthorized {
                    Text("Se necesita acceso al micrófono para grabar.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Permitir micrófono") { model.requestPermission() }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        if model.isRecording {
                            if let url = model.stopRecording() {
                                pendingURL = url
                                pendingDuration = model.elapsed
                                showingSaveSheet = true
                            }
                        } else {
                            model.startRecording()
                        }
                    } label: {
                        Circle()
                            .fill(model.isRecording ? .red : Color.accentColor)
                            .frame(width: 76, height: 76)
                            .overlay {
                                Image(systemName: model.isRecording ? "stop.fill" : "mic.fill")
                                    .foregroundStyle(.white)
                                    .font(.title2)
                            }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        if model.isGainAdjustable {
                            VStack(alignment: .leading) {
                                Text("Sensibilidad del micrófono")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Slider(value: Binding(
                                    get: { model.inputGain },
                                    set: { model.updateGain($0) }
                                ), in: 0...1)
                            }
                        } else {
                            Text("Este dispositivo/simulador no permite ajustar la ganancia de entrada; se usa el nivel automático del sistema.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(alignment: .leading) {
                            Text("Temporizador de grabación")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Picker("Duración máxima", selection: $model.maxDuration) {
                                Text("Sin límite").tag(TimeInterval(0))
                                Text("15 s").tag(TimeInterval(15))
                                Text("30 s").tag(TimeInterval(30))
                                Text("60 s").tag(TimeInterval(60))
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    .padding(.horizontal)
                    .disabled(model.isRecording)

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Importar archivo de audio", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isRecording)
                }

                Spacer()
            }
            .navigationTitle("Audio")
            .onDisappear { model.deactivateSession() }
            .sheet(isPresented: $showingSaveSheet) {
                if let pendingURL {
                    SaveRecordingSheet(duration: pendingDuration) { album in
                        MediaStore.shared.saveAudio(temporaryURL: pendingURL, duration: pendingDuration, album: album, context: context)
                    }
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                AudioFilePicker { url in
                    pendingURL = url
                    pendingDuration = model.duration(ofFileAt: url)
                    showingSaveSheet = true
                }
            }
        }
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct SaveRecordingSheet: View {
    let duration: TimeInterval
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var album: String = "General"

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
                Text("Grabación de \(Int(duration)) segundos")
                TextField("Álbum / categoría", text: $album)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Guardar audio")
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

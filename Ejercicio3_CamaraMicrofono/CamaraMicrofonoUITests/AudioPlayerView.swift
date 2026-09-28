import SwiftUI
import AVFoundation
import CoreData

/// Reproductor de audio para las grabaciones (3.3: "Crear reproductor de audio para las
/// grabaciones realizadas"), con las mismas acciones de metadatos/álbum/eliminar que las fotos.
@MainActor
final class AudioPlaybackModel: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var progress: Double = 0 // 0...1
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(url: URL) {
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        duration = player?.duration ?? 0
    }

    func togglePlayback() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let player = self.player else { return }
                self.currentTime = player.currentTime
                self.progress = self.duration > 0 ? player.currentTime / self.duration : 0
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
    }

    /// Libera la sesión de audio al salir de la pantalla, para no dejarla intentando usar
    /// un dispositivo de salida que quizá no exista en el entorno (ver AudioRecorderModel).
    func deactivateSession() {
        stopTimer()
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension AudioPlaybackModel: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.progress = 0
            self.currentTime = 0
            self.timer?.invalidate()
        }
    }
}

struct AudioPlayerView: View {
    @ObservedObject var item: CapturedItem
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playback = AudioPlaybackModel()

    @State private var tagsText: String = ""
    @State private var albumText: String = ""
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "waveform")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 24)

                VStack(spacing: 8) {
                    ProgressView(value: playback.progress)
                    HStack {
                        Text(formatted(playback.currentTime))
                        Spacer()
                        Text(formatted(playback.duration))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Button {
                    playback.togglePlayback()
                } label: {
                    Image(systemName: playback.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }

                HStack(spacing: 24) {
                    Button {
                        item.isFavorite.toggle()
                        PersistenceController.shared.save()
                    } label: {
                        Label(item.isFavorite ? "Favorito" : "Marcar", systemImage: item.isFavorite ? "star.fill" : "star")
                    }
                }
                .buttonStyle(.bordered)

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Álbum / categoría", text: $albumText, onCommit: saveMetadata)
                        .textFieldStyle(.roundedBorder)
                    TextField("Etiquetas (separadas por coma)", text: $tagsText, onCommit: saveMetadata)
                        .textFieldStyle(.roundedBorder)

                    if let date = item.dateCreated {
                        Text("Grabado el \(date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Audio")
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
            .alert("Eliminar grabación", isPresented: $showingDeleteConfirm) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    MediaStore.shared.delete(item, context: context)
                    dismiss()
                }
            } message: {
                Text("Esta acción no se puede deshacer.")
            }
            .onAppear {
                tagsText = item.tags ?? ""
                albumText = item.albumName ?? "General"
                if let fileName = item.fileName {
                    playback.load(url: MediaStore.shared.url(for: fileName))
                }
            }
            .onDisappear { playback.deactivateSession() }
        }
    }

    private func saveMetadata() {
        item.tags = tagsText
        item.albumName = albumText.isEmpty ? "General" : albumText
        PersistenceController.shared.save()
    }

    private func formatted(_ interval: TimeInterval) -> String {
        guard interval.isFinite, interval >= 0 else { return "00:00" }
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

package mx.ipn.escom.camaramicrofono.platform

import kotlinx.cinterop.ExperimentalForeignApi
import platform.AVFAudio.*
import platform.CoreAudioTypes.*
import platform.Foundation.*

/**
 * Grabador con `AVAudioRecorder` (AAC en .m4a), igual que el Ejercicio 3. La "sensibilidad"
 * usa la ganancia de entrada de `AVAudioSession` cuando el hardware la permite.
 */
@OptIn(ExperimentalForeignApi::class)
actual class AudioRecorder actual constructor() {
    private var recorder: AVAudioRecorder? = null

    actual val fileExtension: String = "m4a"

    actual val isGainAdjustable: Boolean
        get() = AVAudioSession.sharedInstance().inputGainSettable

    actual fun setGain(value: Float) {
        val session = AVAudioSession.sharedInstance()
        if (session.inputGainSettable) session.setInputGain(value.coerceIn(0f, 1f), error = null)
    }

    actual fun start(path: String): Boolean {
        val session = AVAudioSession.sharedInstance()
        session.setCategory(AVAudioSessionCategoryPlayAndRecord, error = null)
        session.setActive(true, error = null)

        val settings = mapOf<Any?, Any?>(
            AVFormatIDKey to NSNumber.numberWithUnsignedInt(kAudioFormatMPEG4AAC),
            AVSampleRateKey to NSNumber.numberWithDouble(44_100.0),
            AVNumberOfChannelsKey to NSNumber.numberWithInt(1),
        )
        val newRecorder = AVAudioRecorder(uRL = NSURL.fileURLWithPath(path), settings = settings, error = null)
        newRecorder.meteringEnabled = true
        if (!newRecorder.record()) {
            // Sin micrófono (p. ej. la VM del Ejercicio 1): se libera la sesión y se usa el respaldo.
            session.setActive(false, error = null)
            return false
        }
        recorder = newRecorder
        return true
    }

    actual fun stop() {
        recorder?.stop()
        recorder = null
    }

    actual fun level(): Float {
        val active = recorder ?: return 0f
        active.updateMeters()
        val decibels = active.averagePowerForChannel(0uL) // típicamente entre -160 y 0 dB
        return ((decibels + 60f) / 60f).coerceIn(0f, 1f)
    }

    actual fun release() {
        stop()
        AVAudioSession.sharedInstance().setActive(false, error = null)
    }
}

/** Reproductor con `AVAudioPlayer` (igual que AudioPlayerView del Ejercicio 3). */
@OptIn(ExperimentalForeignApi::class)
actual class AudioPlayer actual constructor() {
    private var player: AVAudioPlayer? = null

    actual fun load(path: String): Boolean {
        release()
        val session = AVAudioSession.sharedInstance()
        session.setCategory(AVAudioSessionCategoryPlayback, error = null)
        session.setActive(true, error = null)
        val newPlayer = AVAudioPlayer(contentsOfURL = NSURL.fileURLWithPath(path), error = null)
        player = newPlayer
        return newPlayer.prepareToPlay()
    }

    actual fun play() {
        player?.play()
    }

    actual fun pause() {
        player?.pause()
    }

    actual fun seekTo(seconds: Double) {
        player?.currentTime = seconds
    }

    actual val isPlaying: Boolean
        get() = player?.playing == true

    actual val positionSeconds: Double
        get() = player?.currentTime ?: 0.0

    actual val durationSeconds: Double
        get() = player?.duration ?: 0.0

    actual fun release() {
        player?.stop()
        player = null
    }
}

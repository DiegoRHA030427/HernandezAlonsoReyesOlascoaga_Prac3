package mx.ipn.escom.camaramicrofono.platform

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaPlayer
import android.media.MediaRecorder
import mx.ipn.escom.camaramicrofono.util.WavWriter
import java.io.File
import java.io.RandomAccessFile
import kotlin.math.abs

private const val SAMPLE_RATE = WavWriter.DEFAULT_SAMPLE_RATE

/**
 * Grabador con `AudioRecord` (PCM 16 bits mono a 44.1 kHz) que escribe un WAV.
 * A diferencia de `MediaRecorder`, permite aplicar la "sensibilidad" como ganancia por
 * software a cada muestra, y calcular el nivel para el medidor.
 */
actual class AudioRecorder actual constructor() {
    actual val fileExtension: String = "wav"
    actual val isGainAdjustable: Boolean = true

    @Volatile private var gain = 1f
    @Volatile private var currentLevel = 0f
    @Volatile private var recording = false
    private var audioRecord: AudioRecord? = null
    private var worker: Thread? = null

    /** 0 → silencio, 0.5 → nivel normal (x1), 1 → doble de ganancia (x2). */
    actual fun setGain(value: Float) {
        gain = value.coerceIn(0f, 1f) * 2f
    }

    @SuppressLint("MissingPermission") // El permiso RECORD_AUDIO se verifica antes en la UI.
    actual fun start(path: String): Boolean {
        if (recording) return true
        val minBuffer = AudioRecord.getMinBufferSize(SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        if (minBuffer <= 0) return false

        val record = runCatching {
            AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, minBuffer * 2)
        }.getOrNull() ?: return false
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            return false
        }

        val file = runCatching {
            val target = File(path).apply {
                parentFile?.mkdirs()
                delete()
            }
            RandomAccessFile(target, "rw").apply { write(WavWriter.header(0, SAMPLE_RATE)) }
        }.getOrNull()
        if (file == null) {
            record.release()
            return false
        }

        val started = runCatching { record.startRecording() }.isSuccess &&
            record.recordingState == AudioRecord.RECORDSTATE_RECORDING
        if (!started) {
            record.release()
            file.close()
            return false
        }

        audioRecord = record
        recording = true
        worker = Thread {
            val samples = ShortArray(minBuffer / 2)
            val bytes = ByteArray(samples.size * 2)
            var dataSize = 0
            val startNanos = System.nanoTime()
            try {
                while (recording) {
                    val read = record.read(samples, 0, samples.size)
                    if (read < 0) break
                    // Algunos emuladores sin micrófono del host entregan muestras más rápido que el
                    // tiempo real; se descarta el excedente para que la duración del WAV coincida
                    // con la grabación. En un teléfono real `read` bloquea y esto nunca recorta nada.
                    val elapsedBytes = ((System.nanoTime() - startNanos) / 1_000_000_000.0 * SAMPLE_RATE).toLong() * 2
                    val allowedSamples = ((elapsedBytes + minBuffer - dataSize) / 2).coerceIn(0L, read.toLong()).toInt()
                    if (allowedSamples == 0) {
                        Thread.sleep(5)
                        continue
                    }
                    var peak = 0
                    for (i in 0 until allowedSamples) {
                        val value = (samples[i] * gain).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                        val magnitude = abs(value)
                        if (magnitude > peak) peak = magnitude
                        bytes[2 * i] = (value and 0xFF).toByte()
                        bytes[2 * i + 1] = ((value shr 8) and 0xFF).toByte()
                    }
                    if (allowedSamples > 0) {
                        file.write(bytes, 0, allowedSamples * 2)
                        dataSize += allowedSamples * 2
                        currentLevel = peak / Short.MAX_VALUE.toFloat()
                    }
                }
            } finally {
                // Reescribe el encabezado con el tamaño real de los datos.
                runCatching {
                    file.seek(0)
                    file.write(WavWriter.header(dataSize, SAMPLE_RATE))
                }
                file.close()
            }
        }.apply { start() }
        return true
    }

    actual fun stop() {
        if (!recording && audioRecord == null) return
        recording = false
        worker?.join(2_000)
        worker = null
        audioRecord?.let {
            runCatching { it.stop() }
            it.release()
        }
        audioRecord = null
        currentLevel = 0f
    }

    actual fun level(): Float = currentLevel

    actual fun release() {
        stop()
    }
}

/** Reproductor con `MediaPlayer` (equivalente a AVAudioPlayer). */
actual class AudioPlayer actual constructor() {
    private var player: MediaPlayer? = null

    actual fun load(path: String): Boolean {
        release()
        return runCatching {
            player = MediaPlayer().apply {
                setDataSource(path)
                prepare()
            }
            true
        }.getOrDefault(false)
    }

    actual fun play() {
        player?.start()
    }

    actual fun pause() {
        player?.takeIf { it.isPlaying }?.pause()
    }

    actual fun seekTo(seconds: Double) {
        player?.seekTo((seconds * 1000).toInt())
    }

    actual val isPlaying: Boolean
        get() = runCatching { player?.isPlaying == true }.getOrDefault(false)

    actual val positionSeconds: Double
        get() = (player?.currentPosition ?: 0) / 1000.0

    actual val durationSeconds: Double
        get() = (player?.duration ?: 0).coerceAtLeast(0) / 1000.0

    actual fun release() {
        player?.release()
        player = null
    }
}

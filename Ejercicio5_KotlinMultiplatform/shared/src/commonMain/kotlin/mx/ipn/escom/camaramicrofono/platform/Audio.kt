package mx.ipn.escom.camaramicrofono.platform

/**
 * Grabador de audio nativo (expect/actual):
 * - Android: `AudioRecord` (PCM 16 bits, 44.1 kHz) guardado como WAV. Permite
 *   ajustar la sensibilidad aplicando ganancia por software a cada muestra.
 * - iOS: `AVAudioRecorder` (AAC en .m4a), igual que el Ejercicio 3. La sensibilidad
 *   usa la ganancia de entrada de `AVAudioSession` cuando el hardware lo permite.
 */
expect class AudioRecorder() {
    /** Extensión del archivo que genera la plataforma ("wav" o "m4a"). */
    val fileExtension: String

    /** true si se puede ajustar la sensibilidad del micrófono. */
    val isGainAdjustable: Boolean

    /** Sensibilidad de 0 a 1 (0.5 = nivel normal). */
    fun setGain(value: Float)

    /** Empieza a grabar en [path]. Devuelve false si no hay micrófono disponible. */
    fun start(path: String): Boolean

    fun stop()

    /** Nivel de entrada normalizado de 0 a 1 para el medidor. */
    fun level(): Float

    fun release()
}

/** Reproductor de audio nativo (`MediaPlayer` en Android, `AVAudioPlayer` en iOS). */
expect class AudioPlayer() {
    fun load(path: String): Boolean

    fun play()

    fun pause()

    fun seekTo(seconds: Double)

    val isPlaying: Boolean

    val positionSeconds: Double

    val durationSeconds: Double

    fun release()
}

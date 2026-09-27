package mx.ipn.escom.camaramicrofono.util

/**
 * Genera archivos WAV (PCM 16 bits, mono) en Kotlin puro.
 * - [header] lo usa el grabador de Android para escribir el encabezado del archivo.
 * - [silence] genera el audio de respaldo cuando no hay micrófono disponible,
 *   igual que la solución del Ejercicio 3 para la VM sin hardware de audio.
 */
object WavWriter {
    const val DEFAULT_SAMPLE_RATE = 44_100
    const val HEADER_SIZE = 44

    fun header(dataSize: Int, sampleRate: Int = DEFAULT_SAMPLE_RATE, channels: Int = 1, bitsPerSample: Int = 16): ByteArray {
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8
        val out = ByteArray(HEADER_SIZE)
        var i = 0
        fun ascii(text: String) = text.forEach { out[i++] = it.code.toByte() }
        fun int32(value: Int) {
            out[i++] = (value and 0xFF).toByte()
            out[i++] = ((value shr 8) and 0xFF).toByte()
            out[i++] = ((value shr 16) and 0xFF).toByte()
            out[i++] = ((value shr 24) and 0xFF).toByte()
        }
        fun int16(value: Int) {
            out[i++] = (value and 0xFF).toByte()
            out[i++] = ((value shr 8) and 0xFF).toByte()
        }
        ascii("RIFF"); int32(36 + dataSize); ascii("WAVE")
        ascii("fmt "); int32(16); int16(1); int16(channels)
        int32(sampleRate); int32(byteRate); int16(blockAlign); int16(bitsPerSample)
        ascii("data"); int32(dataSize)
        return out
    }

    /** WAV silencioso de [seconds] segundos (a 8 kHz para que el archivo sea pequeño). */
    fun silence(seconds: Double, sampleRate: Int = 8_000): ByteArray {
        val samples = (seconds.coerceAtLeast(0.1) * sampleRate).toInt()
        val dataSize = samples * 2
        return header(dataSize, sampleRate) + ByteArray(dataSize)
    }
}

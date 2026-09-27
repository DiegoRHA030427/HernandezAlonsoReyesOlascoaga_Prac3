package mx.ipn.escom.camaramicrofono

import mx.ipn.escom.camaramicrofono.domain.AppThemeOption
import mx.ipn.escom.camaramicrofono.domain.AppearanceMode
import mx.ipn.escom.camaramicrofono.domain.GeoPoint
import mx.ipn.escom.camaramicrofono.domain.MediaItem
import mx.ipn.escom.camaramicrofono.domain.MediaType
import mx.ipn.escom.camaramicrofono.util.WavWriter
import mx.ipn.escom.camaramicrofono.util.albumFilterOptions
import mx.ipn.escom.camaramicrofono.util.decimals
import mx.ipn.escom.camaramicrofono.util.formatCoordinates
import mx.ipn.escom.camaramicrofono.util.formatDuration
import mx.ipn.escom.camaramicrofono.util.normalizeAlbum
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Pruebas de la lógica compartida (commonMain). Se ejecutan con:
 *   gradlew :shared:testAndroidHostTest
 */
class SharedLogicTest {

    @Test
    fun formatoDeDuracion() {
        assertEquals("00:00", formatDuration(0.0))
        assertEquals("00:16", formatDuration(16.4))
        assertEquals("01:05", formatDuration(65.0))
        assertEquals("00:00", formatDuration(-3.0))
    }

    @Test
    fun formatoDeCoordenadas() {
        assertEquals("19.5", decimals(19.5, 1))
        assertEquals("0.05", decimals(0.049999, 2))
        assertEquals("19.50460° N, 99.14690° O", formatCoordinates(19.5046, -99.1469))
    }

    @Test
    fun albumPorDefecto() {
        assertEquals("General", normalizeAlbum("   "))
        assertEquals("Viaje", normalizeAlbum("  Viaje "))
    }

    @Test
    fun opcionesDelFiltroDeAlbumes() {
        val options = albumFilterOptions(listOf("Viaje", "General", "Escuela", "Viaje"))
        assertEquals(listOf("Todos", "Escuela", "General", "Viaje"), options)
    }

    @Test
    fun encabezadoWavValido() {
        val header = WavWriter.header(dataSize = 1000, sampleRate = 44_100)
        assertEquals(WavWriter.HEADER_SIZE, header.size)
        assertEquals("RIFF", header.copyOfRange(0, 4).decodeToString())
        assertEquals("WAVE", header.copyOfRange(8, 12).decodeToString())
        assertEquals("data", header.copyOfRange(36, 40).decodeToString())
        // Tamaño total = 36 + datos (little endian).
        assertEquals(1036, readInt32(header, 4))
        assertEquals(44_100, readInt32(header, 24))
    }

    @Test
    fun audioDeRespaldoSilencioso() {
        val wav = WavWriter.silence(seconds = 2.0, sampleRate = 8_000)
        assertEquals(WavWriter.HEADER_SIZE + 2 * 8_000 * 2, wav.size)
        assertTrue(wav.drop(WavWriter.HEADER_SIZE).all { it == 0.toByte() })
    }

    @Test
    fun conversionDeTiposYPreferencias() {
        assertEquals(MediaType.AUDIO, MediaType.fromRaw("audio"))
        assertEquals(MediaType.PHOTO, MediaType.fromRaw("desconocido"))
        assertEquals(AppThemeOption.AZUL, AppThemeOption.fromName("AZUL"))
        assertEquals(AppThemeOption.GUINDA, AppThemeOption.fromName(null))
        assertEquals(AppearanceMode.SISTEMA, AppearanceMode.fromName("otro"))
    }

    @Test
    fun mimeTypeParaCompartir() {
        fun item(type: MediaType, name: String) = MediaItem(
            id = "1", type = type, fileName = name, dateCreated = 0L, albumName = "General",
            tags = "", isFavorite = false, location = GeoPoint(0.0, 0.0), durationSeconds = 0.0,
        )
        assertEquals("image/jpeg", item(MediaType.PHOTO, "IMG_1.jpg").mimeType)
        assertEquals("audio/wav", item(MediaType.AUDIO, "REC_1.wav").mimeType)
        assertEquals("audio/mp4", item(MediaType.AUDIO, "REC_1.m4a").mimeType)
    }

    private fun readInt32(bytes: ByteArray, offset: Int): Int =
        (bytes[offset].toInt() and 0xFF) or
            ((bytes[offset + 1].toInt() and 0xFF) shl 8) or
            ((bytes[offset + 2].toInt() and 0xFF) shl 16) or
            ((bytes[offset + 3].toInt() and 0xFF) shl 24)
}

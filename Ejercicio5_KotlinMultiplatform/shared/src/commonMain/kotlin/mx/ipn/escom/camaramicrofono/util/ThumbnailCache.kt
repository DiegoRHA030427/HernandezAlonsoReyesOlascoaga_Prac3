package mx.ipn.escom.camaramicrofono.util

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.ImageBitmap

/**
 * Caché en memoria de miniaturas decodificadas (equivalente a `MediaThumbnailCache`
 * con NSCache del Ejercicio 3): la galería no vuelve a leer ni decodificar cada foto.
 * Es un LRU sencillo con un máximo de [MAX_ENTRIES] imágenes.
 */
object ThumbnailCache {
    private const val MAX_ENTRIES = 80
    private val entries = LinkedHashMap<String, ImageBitmap>()

    /** Cambia cada vez que se edita una foto, para que la UI vuelva a cargarla. */
    var revision by mutableIntStateOf(0)
        private set

    fun get(key: String): ImageBitmap? = entries[key]?.also {
        // Reinsertar para marcarla como usada recientemente.
        entries.remove(key)
        entries[key] = it
    }

    fun put(key: String, image: ImageBitmap) {
        entries[key] = image
        while (entries.size > MAX_ENTRIES) {
            entries.remove(entries.keys.first())
        }
    }

    /** Descarta todas las versiones cacheadas de un archivo (tras rotar o aplicar un filtro). */
    fun invalidate(fileName: String) {
        entries.keys.filter { it.startsWith("$fileName#") }.forEach { entries.remove(it) }
        revision++
    }
}

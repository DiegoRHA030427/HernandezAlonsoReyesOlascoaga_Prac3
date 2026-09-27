package mx.ipn.escom.camaramicrofono.domain

/** Tipo de contenido capturado (igual que `MediaType` del Ejercicio 3). */
enum class MediaType(val raw: String) {
    PHOTO("photo"),
    AUDIO("audio");

    companion object {
        fun fromRaw(raw: String): MediaType = entries.firstOrNull { it.raw == raw } ?: PHOTO
    }
}

/** Coordenadas opcionales para los metadatos. */
data class GeoPoint(val latitude: Double, val longitude: Double)

/**
 * Foto o audio capturado. Mismos campos que la entidad `CapturedItem`
 * de Core Data del Ejercicio 3, pero como modelo de dominio independiente
 * de la base de datos.
 */
data class MediaItem(
    val id: String,
    val type: MediaType,
    val fileName: String,
    val dateCreated: Long,
    val albumName: String,
    val tags: String,
    val isFavorite: Boolean,
    val location: GeoPoint?,
    val durationSeconds: Double,
) {
    val isPhoto: Boolean get() = type == MediaType.PHOTO
    val isAudio: Boolean get() = type == MediaType.AUDIO

    /** MIME para compartir el archivo con otras apps. */
    val mimeType: String
        get() = when {
            isPhoto -> "image/jpeg"
            fileName.endsWith(".wav", ignoreCase = true) -> "audio/wav"
            else -> "audio/mp4"
        }
}

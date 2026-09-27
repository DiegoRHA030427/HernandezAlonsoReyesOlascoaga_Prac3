package mx.ipn.escom.camaramicrofono.data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import mx.ipn.escom.camaramicrofono.db.CamaraMicrofonoDatabase
import mx.ipn.escom.camaramicrofono.db.CapturedItem
import mx.ipn.escom.camaramicrofono.domain.GeoPoint
import mx.ipn.escom.camaramicrofono.domain.MediaItem
import mx.ipn.escom.camaramicrofono.domain.MediaType
import mx.ipn.escom.camaramicrofono.platform.FileStorage
import mx.ipn.escom.camaramicrofono.platform.currentTimeMillis
import mx.ipn.escom.camaramicrofono.util.ThumbnailCache
import mx.ipn.escom.camaramicrofono.util.normalizeAlbum
import kotlin.uuid.ExperimentalUuidApi
import kotlin.uuid.Uuid

/**
 * Centraliza el guardado físico de archivos y el registro de sus metadatos en SQLDelight
 * (equivalente a `MediaStore` + Core Data del Ejercicio 3).
 */
class MediaRepository(database: CamaraMicrofonoDatabase) {
    private val queries = database.capturedItemQueries

    /** Todas las capturas, más recientes primero. Se actualiza sola cuando cambia la tabla. */
    val items: Flow<List<MediaItem>> = queries.selectAll()
        .asFlow()
        .mapToList(Dispatchers.Default)
        .map { rows -> rows.map { it.toDomain() } }

    fun pathOf(item: MediaItem): String = FileStorage.mediaPath(item.fileName)

    // -- Guardar foto --------------------------------------------------------

    suspend fun savePhoto(jpeg: ByteArray, album: String, location: GeoPoint?): MediaItem? =
        withContext(Dispatchers.Default) {
            val fileName = "IMG_${currentTimeMillis()}.jpg"
            if (!FileStorage.writeBytes(FileStorage.mediaPath(fileName), jpeg)) return@withContext null
            insert(MediaType.PHOTO, fileName, album, location, durationSeconds = 0.0)
        }

    /** Sobrescribe una foto ya guardada (edición básica: rotar / reaplicar filtro). */
    suspend fun overwritePhoto(item: MediaItem, jpeg: ByteArray): Boolean =
        withContext(Dispatchers.Default) {
            FileStorage.writeBytes(pathOf(item), jpeg)
        }.also { ok -> if (ok) ThumbnailCache.invalidate(item.fileName) }

    // -- Guardar audio -------------------------------------------------------

    /** Mueve la grabación temporal a "Capturas" y registra sus metadatos. */
    suspend fun saveAudio(temporaryPath: String, durationSeconds: Double, album: String): MediaItem? =
        withContext(Dispatchers.Default) {
            val extension = temporaryPath.substringAfterLast('.', "m4a")
            val fileName = "REC_${currentTimeMillis()}.$extension"
            if (!FileStorage.move(temporaryPath, FileStorage.mediaPath(fileName))) return@withContext null
            insert(MediaType.AUDIO, fileName, album, location = null, durationSeconds = durationSeconds)
        }

    // -- Edición de metadatos -------------------------------------------------

    fun setFavorite(item: MediaItem, favorite: Boolean) {
        queries.updateFavorite(isFavorite = if (favorite) 1L else 0L, id = item.id)
    }

    fun updateAlbumAndTags(item: MediaItem, album: String, tags: String) {
        queries.updateAlbumAndTags(albumName = normalizeAlbum(album), tags = tags.trim(), id = item.id)
    }

    suspend fun delete(item: MediaItem) {
        withContext(Dispatchers.Default) { FileStorage.delete(pathOf(item)) }
        ThumbnailCache.invalidate(item.fileName)
        queries.deleteById(item.id)
    }

    // -- Privado ---------------------------------------------------------------

    @OptIn(ExperimentalUuidApi::class)
    private fun insert(
        type: MediaType,
        fileName: String,
        album: String,
        location: GeoPoint?,
        durationSeconds: Double,
    ): MediaItem {
        val item = MediaItem(
            id = Uuid.random().toString(),
            type = type,
            fileName = fileName,
            dateCreated = currentTimeMillis(),
            albumName = normalizeAlbum(album),
            tags = "",
            isFavorite = false,
            location = location,
            durationSeconds = durationSeconds,
        )
        queries.insert(
            id = item.id,
            type = item.type.raw,
            fileName = item.fileName,
            dateCreated = item.dateCreated,
            albumName = item.albumName,
            tags = item.tags,
            isFavorite = 0L,
            latitude = location?.latitude ?: 0.0,
            longitude = location?.longitude ?: 0.0,
            hasLocation = if (location != null) 1L else 0L,
            duration = durationSeconds,
        )
        return item
    }
}

/** Convierte la fila generada por SQLDelight al modelo de dominio. */
internal fun CapturedItem.toDomain(): MediaItem = MediaItem(
    id = id,
    type = MediaType.fromRaw(type),
    fileName = fileName,
    dateCreated = dateCreated,
    albumName = albumName,
    tags = tags,
    isFavorite = isFavorite != 0L,
    location = if (hasLocation != 0L) GeoPoint(latitude, longitude) else null,
    durationSeconds = duration,
)

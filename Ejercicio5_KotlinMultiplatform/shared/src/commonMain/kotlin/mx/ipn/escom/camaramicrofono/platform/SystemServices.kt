package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.runtime.Composable
import mx.ipn.escom.camaramicrofono.domain.GeoPoint

/**
 * Ubicación opcional para los metadatos (igual que `LocationHelper` del Ejercicio 3).
 * Usa el GPS / última ubicación conocida, por lo que funciona sin internet.
 * Devuelve null si no hay permiso o no hay ubicación disponible.
 */
expect object LocationProvider {
    suspend fun currentLocation(): GeoPoint?
}

/** Hoja de compartir del sistema (Intent.ACTION_SEND / UIActivityViewController). */
expect object ShareHelper {
    fun share(path: String, mimeType: String)
}

/** Botón "atrás" del sistema (Android). En iOS no existe, así que no hace nada. */
@Composable
expect fun PlatformBackHandler(enabled: Boolean = true, onBack: () -> Unit)

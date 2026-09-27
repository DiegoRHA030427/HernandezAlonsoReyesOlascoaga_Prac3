package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/**
 * Cámara nativa. La lógica de la pantalla (filtros, flash, temporizador, guardado)
 * es común; solo la captura cambia entre plataformas:
 * - Android: CameraX con vista previa en vivo dentro de la app.
 * - iOS: `UIImagePickerController` (visor de cámara del sistema). En el simulador,
 *   que no tiene cámara, abre la fototeca como alternativa (igual que el Ejercicio 3).
 */
interface CameraController {
    /** true si la app muestra la vista previa en vivo ([Preview]). */
    val hasLivePreview: Boolean

    /** Vista previa en vivo de la cámara (vacía si [hasLivePreview] es false). */
    @Composable
    fun Preview(modifier: Modifier)

    /** Toma la foto y entrega los bytes JPEG, o null si se canceló o falló. */
    fun takePicture(flashOn: Boolean, onResult: (ByteArray?) -> Unit)
}

@Composable
expect fun rememberCameraController(): CameraController

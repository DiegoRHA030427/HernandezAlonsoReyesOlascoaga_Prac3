package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.ui.graphics.ImageBitmap
import mx.ipn.escom.camaramicrofono.domain.PhotoFilter

/**
 * Procesamiento de imágenes nativo (expect/actual):
 * - Android: `Bitmap` + `ColorMatrix`.
 * - iOS: Core Image (`CIFilter`) con renderizado por software, igual que el
 *   Ejercicio 3 (la VM de macOS no tiene aceleración GPU/Metal).
 * Todas las funciones reciben y devuelven JPEG.
 */
expect object ImageProcessor {
    fun applyFilter(jpeg: ByteArray, filter: PhotoFilter): ByteArray

    /** Rota la imagen [degrees] grados en sentido horario (múltiplos de 90). */
    fun rotate(jpeg: ByteArray, degrees: Int): ByteArray

    /** Versión reducida (lado mayor = [maxSize] px) para miniaturas y vistas previas. */
    fun thumbnail(jpeg: ByteArray, maxSize: Int): ByteArray

    /** Decodifica los bytes a una imagen que Compose puede dibujar. */
    fun decode(bytes: ByteArray): ImageBitmap?
}

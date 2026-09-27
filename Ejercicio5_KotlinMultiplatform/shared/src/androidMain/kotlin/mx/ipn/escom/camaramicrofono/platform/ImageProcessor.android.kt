package mx.ipn.escom.camaramicrofono.platform

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Matrix
import android.graphics.Paint
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import mx.ipn.escom.camaramicrofono.domain.PhotoFilter
import java.io.ByteArrayOutputStream
import kotlin.math.max

/** Filtros y transformaciones con Bitmap + ColorMatrix (equivalente a Core Image). */
actual object ImageProcessor {

    actual fun applyFilter(jpeg: ByteArray, filter: PhotoFilter): ByteArray {
        if (filter == PhotoFilter.NINGUNO) return jpeg
        val source = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size) ?: return jpeg
        val output = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.FILTER_BITMAP_FLAG).apply {
            colorFilter = ColorMatrixColorFilter(matrixFor(filter))
        }
        Canvas(output).drawBitmap(source, 0f, 0f, paint)
        return output.toJpeg()
    }

    private fun matrixFor(filter: PhotoFilter): ColorMatrix = when (filter) {
        // Matriz sepia clásica (similar a CISepiaTone con intensidad ~0.85).
        PhotoFilter.SEPIA -> ColorMatrix(
            floatArrayOf(
                0.393f, 0.769f, 0.189f, 0f, 0f,
                0.349f, 0.686f, 0.168f, 0f, 0f,
                0.272f, 0.534f, 0.131f, 0f, 0f,
                0f, 0f, 0f, 1f, 0f,
            )
        )
        // Escala de grises (equivalente a CIPhotoEffectMono).
        PhotoFilter.BLANCO_Y_NEGRO -> ColorMatrix().apply { setSaturation(0f) }
        // Más saturación (equivalente a CIVibrance).
        PhotoFilter.VIVIDO -> ColorMatrix().apply { setSaturation(1.6f) }
        PhotoFilter.NINGUNO -> ColorMatrix()
    }

    actual fun rotate(jpeg: ByteArray, degrees: Int): ByteArray {
        val source = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size) ?: return jpeg
        val matrix = Matrix().apply { postRotate(degrees.toFloat()) }
        return Bitmap.createBitmap(source, 0, 0, source.width, source.height, matrix, true).toJpeg()
    }

    actual fun thumbnail(jpeg: ByteArray, maxSize: Int): ByteArray {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size, bounds)
        val largest = max(bounds.outWidth, bounds.outHeight)
        if (largest <= 0) return jpeg
        if (largest <= maxSize) return jpeg

        // Decodifica a una fracción del tamaño (potencia de 2) para ahorrar memoria.
        var sample = 1
        while (largest / (sample * 2) >= maxSize) sample *= 2
        val decoded = BitmapFactory.decodeByteArray(jpeg, 0, jpeg.size, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: return jpeg
        val scale = maxSize.toFloat() / max(decoded.width, decoded.height)
        val scaled = if (scale < 1f) {
            Bitmap.createScaledBitmap(decoded, (decoded.width * scale).toInt(), (decoded.height * scale).toInt(), true)
        } else {
            decoded
        }
        return scaled.toJpeg(quality = 85)
    }

    actual fun decode(bytes: ByteArray): ImageBitmap? =
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size)?.asImageBitmap()

    private fun Bitmap.toJpeg(quality: Int = 90): ByteArray =
        ByteArrayOutputStream().use { out ->
            compress(Bitmap.CompressFormat.JPEG, quality, out)
            out.toByteArray()
        }
}

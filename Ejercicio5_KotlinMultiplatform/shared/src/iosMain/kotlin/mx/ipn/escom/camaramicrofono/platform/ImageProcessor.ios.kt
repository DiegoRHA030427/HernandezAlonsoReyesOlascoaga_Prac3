package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.toComposeImageBitmap
import kotlinx.cinterop.CValue
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import mx.ipn.escom.camaramicrofono.domain.PhotoFilter
import org.jetbrains.skia.Image
import platform.CoreGraphics.*
import platform.CoreImage.*
import platform.Foundation.*
import platform.UIKit.*
import kotlin.math.PI
import kotlin.math.max

/**
 * Filtros con Core Image (los mismos CIFilter del Ejercicio 3) y transformaciones con UIKit.
 * El CIContext usa renderizado por software, como la solución del Ejercicio 3 para la VM
 * de macOS sin aceleración GPU/Metal.
 */
@OptIn(ExperimentalForeignApi::class)
actual object ImageProcessor {
    private val context: CIContext by lazy {
        CIContext.contextWithOptions(mapOf<Any?, Any?>(kCIContextUseSoftwareRenderer to true))
    }

    actual fun applyFilter(jpeg: ByteArray, filter: PhotoFilter): ByteArray {
        if (filter == PhotoFilter.NINGUNO) return jpeg
        val input = CIImage.imageWithData(jpeg.toNSData()) ?: return jpeg
        val ciFilter = when (filter) {
            PhotoFilter.SEPIA -> CIFilter.filterWithName("CISepiaTone")?.apply {
                setValue(NSNumber.numberWithDouble(0.85), forKey = "inputIntensity")
            }
            PhotoFilter.BLANCO_Y_NEGRO -> CIFilter.filterWithName("CIPhotoEffectMono")
            PhotoFilter.VIVIDO -> CIFilter.filterWithName("CIVibrance")?.apply {
                setValue(NSNumber.numberWithDouble(1.0), forKey = "inputAmount")
            }
            PhotoFilter.NINGUNO -> null
        } ?: return jpeg
        ciFilter.setValue(input, forKey = kCIInputImageKey)
        val output = ciFilter.outputImage ?: return jpeg
        return render(output, input.extent) ?: jpeg
    }

    private fun render(image: CIImage, extent: CValue<CGRect>): ByteArray? {
        val cgImage = context.createCGImage(image, fromRect = extent) ?: return null
        val uiImage = UIImage.imageWithCGImage(cgImage)
        CGImageRelease(cgImage)
        return UIImageJPEGRepresentation(uiImage, 0.9)?.toByteArray()
    }

    actual fun rotate(jpeg: ByteArray, degrees: Int): ByteArray {
        val image = UIImage.imageWithData(jpeg.toNSData()) ?: return jpeg
        val (width, height) = image.size.useContents { width to height }
        val swap = (degrees / 90) % 2 != 0
        val newWidth = if (swap) height else width
        val newHeight = if (swap) width else height

        UIGraphicsBeginImageContextWithOptions(CGSizeMake(newWidth, newHeight), false, 1.0)
        val graphics = UIGraphicsGetCurrentContext()
        CGContextTranslateCTM(graphics, newWidth / 2, newHeight / 2)
        CGContextRotateCTM(graphics, degrees * PI / 180.0)
        image.drawInRect(CGRectMake(-width / 2, -height / 2, width, height))
        val rotated = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotated?.let { UIImageJPEGRepresentation(it, 0.9)?.toByteArray() } ?: jpeg
    }

    actual fun thumbnail(jpeg: ByteArray, maxSize: Int): ByteArray {
        val image = UIImage.imageWithData(jpeg.toNSData()) ?: return jpeg
        val (width, height) = image.size.useContents { width to height }
        val largest = max(width, height)
        if (largest <= maxSize) return jpeg
        val scale = maxSize / largest
        return redraw(image, width * scale, height * scale, quality = 0.85) ?: jpeg
    }

    actual fun decode(bytes: ByteArray): ImageBitmap? =
        runCatching { Image.makeFromEncoded(bytes).toComposeImageBitmap() }.getOrNull()

    /** Redibuja un UIImage (aplica su orientación) y lo devuelve como JPEG. */
    internal fun redraw(image: UIImage, width: Double, height: Double, quality: Double = 0.9): ByteArray? {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), false, 1.0)
        image.drawInRect(CGRectMake(0.0, 0.0, width, height))
        val result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result?.let { UIImageJPEGRepresentation(it, quality)?.toByteArray() }
    }
}

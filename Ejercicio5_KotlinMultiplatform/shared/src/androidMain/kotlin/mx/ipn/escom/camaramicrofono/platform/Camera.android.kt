package mx.ipn.escom.camaramicrofono.platform

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.ImageProxy
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors
import androidx.camera.core.Preview as CameraXPreview

@Composable
actual fun rememberCameraController(): CameraController {
    val context = LocalContext.current
    return remember { AndroidCameraController(context.applicationContext) }
}

/**
 * Cámara con CameraX (equivalente a AVCaptureSession + AVCapturePhotoOutput del Ejercicio 3):
 * vista previa en vivo con `PreviewView` y captura con `ImageCapture`.
 * En el emulador de Android funciona con la cámara virtual (escena 3D).
 */
private class AndroidCameraController(private val appContext: Context) : CameraController {
    override val hasLivePreview: Boolean = true

    private val imageCapture = ImageCapture.Builder()
        .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
        .build()
    private val captureExecutor = Executors.newSingleThreadExecutor()

    @Composable
    override fun Preview(modifier: Modifier) {
        val context = LocalContext.current
        val lifecycleOwner = LocalLifecycleOwner.current
        val previewView = remember {
            PreviewView(context).apply { scaleType = PreviewView.ScaleType.FILL_CENTER }
        }

        DisposableEffect(lifecycleOwner) {
            val providerFuture = ProcessCameraProvider.getInstance(context)
            var provider: ProcessCameraProvider? = null
            providerFuture.addListener({
                val cameraProvider = providerFuture.get()
                provider = cameraProvider
                val preview = CameraXPreview.Builder().build().also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }
                val selector = if (runCatching { cameraProvider.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA) }.getOrDefault(false)) {
                    CameraSelector.DEFAULT_BACK_CAMERA
                } else {
                    CameraSelector.DEFAULT_FRONT_CAMERA
                }
                runCatching {
                    cameraProvider.unbindAll()
                    cameraProvider.bindToLifecycle(lifecycleOwner, selector, preview, imageCapture)
                }
            }, ContextCompat.getMainExecutor(context))

            onDispose { provider?.unbindAll() }
        }

        AndroidView(factory = { previewView }, modifier = modifier)
    }

    override fun takePicture(flashOn: Boolean, onResult: (ByteArray?) -> Unit) {
        imageCapture.flashMode = if (flashOn) ImageCapture.FLASH_MODE_ON else ImageCapture.FLASH_MODE_OFF
        imageCapture.takePicture(captureExecutor, object : ImageCapture.OnImageCapturedCallback() {
            override fun onCaptureSuccess(image: ImageProxy) {
                val bytes = runCatching { image.toUprightJpeg() }.getOrNull()
                image.close()
                onResult(bytes)
            }

            override fun onError(exception: ImageCaptureException) {
                onResult(null)
            }
        })
    }

    /** Convierte el frame a JPEG aplicando la rotación del sensor. */
    private fun ImageProxy.toUprightJpeg(): ByteArray {
        val bitmap = toBitmap()
        val rotation = imageInfo.rotationDegrees
        val upright = if (rotation != 0) {
            val matrix = Matrix().apply { postRotate(rotation.toFloat()) }
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
        } else {
            bitmap
        }
        return ByteArrayOutputStream().use { out ->
            upright.compress(Bitmap.CompressFormat.JPEG, 90, out)
            out.toByteArray()
        }
    }
}

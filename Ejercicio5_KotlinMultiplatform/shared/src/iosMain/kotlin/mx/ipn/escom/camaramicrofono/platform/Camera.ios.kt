package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import platform.Foundation.*
import platform.UIKit.*
import platform.darwin.NSObject

@Composable
actual fun rememberCameraController(): CameraController = remember { IosCameraController() }

/**
 * Cámara en iOS con `UIImagePickerController`: abre el visor de cámara del sistema y, si no hay
 * cámara física (simulador), la fototeca como alternativa documentada, igual que el Ejercicio 3.
 */
private class IosCameraController : CameraController {
    override val hasLivePreview: Boolean = false

    // Referencia fuerte al delegate mientras el selector está abierto (UIKit solo guarda una débil).
    private var delegate: ImagePickerDelegate? = null

    @Composable
    override fun Preview(modifier: Modifier) {
        // Sin vista previa en vivo: la captura ocurre en el visor del sistema.
    }

    override fun takePicture(flashOn: Boolean, onResult: (ByteArray?) -> Unit) {
        val presenter = topViewController() ?: run {
            onResult(null)
            return
        }
        val hasCamera = UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera
        )
        val picker = UIImagePickerController()
        picker.sourceType = if (hasCamera) {
            UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera
        } else {
            UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypePhotoLibrary
        }
        if (hasCamera) {
            picker.cameraFlashMode = if (flashOn) {
                UIImagePickerControllerCameraFlashMode.UIImagePickerControllerCameraFlashModeOn
            } else {
                UIImagePickerControllerCameraFlashMode.UIImagePickerControllerCameraFlashModeOff
            }
        }
        val pickerDelegate = ImagePickerDelegate { bytes ->
            delegate = null
            onResult(bytes)
        }
        delegate = pickerDelegate
        picker.delegate = pickerDelegate
        presenter.presentViewController(picker, animated = true, completion = null)
    }
}

private class ImagePickerDelegate(
    private val onFinish: (ByteArray?) -> Unit,
) : NSObject(), UIImagePickerControllerDelegateProtocol, UINavigationControllerDelegateProtocol {

    @OptIn(ExperimentalForeignApi::class)
    override fun imagePickerController(
        picker: UIImagePickerController,
        didFinishPickingMediaWithInfo: Map<Any?, *>,
    ) {
        val image = didFinishPickingMediaWithInfo[UIImagePickerControllerOriginalImage] as? UIImage
        picker.dismissViewControllerAnimated(true, completion = null)
        // Se redibuja para "aplicar" la orientación EXIF antes de guardar el JPEG.
        val bytes = image?.let {
            val (width, height) = it.size.useContents { width to height }
            ImageProcessor.redraw(it, width, height)
        }
        onFinish(bytes)
    }

    override fun imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion = null)
        onFinish(null)
    }
}

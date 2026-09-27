package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import platform.AVFAudio.*
import platform.AVFoundation.*
import platform.CoreLocation.*
import platform.UIKit.*
import platform.darwin.dispatch_async
import platform.darwin.dispatch_get_main_queue

/**
 * Permisos en tiempo de ejecución con las APIs nativas de iOS. Las descripciones que ve el
 * usuario se declaran en `iosApp/iosApp/Info.plist` (NSCameraUsageDescription, etc.).
 */
@Composable
actual fun rememberPermissionState(permission: AppPermission): PermissionState =
    remember(permission) { IosPermissionState(permission) }

private class IosPermissionState(private val permission: AppPermission) : PermissionState {
    private var granted by mutableStateOf(false)

    init {
        granted = check()
    }

    override val isGranted: Boolean get() = granted

    private fun check(): Boolean = when (permission) {
        AppPermission.CAMERA ->
            // En el simulador no hay cámara: se usa la fototeca, que no requiere este permiso.
            !UIImagePickerController.isSourceTypeAvailable(
                UIImagePickerControllerSourceType.UIImagePickerControllerSourceTypeCamera
            ) || AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatusAuthorized

        AppPermission.MICROPHONE ->
            AVAudioSession.sharedInstance().recordPermission == AVAudioSessionRecordPermissionGranted

        AppPermission.LOCATION -> LocationProvider.isAuthorized()
    }

    override fun request() {
        when (permission) {
            AppPermission.CAMERA -> AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { ok ->
                dispatch_async(dispatch_get_main_queue()) { granted = ok || check() }
            }

            AppPermission.MICROPHONE -> AVAudioSession.sharedInstance().requestRecordPermission { ok ->
                dispatch_async(dispatch_get_main_queue()) { granted = ok }
            }

            AppPermission.LOCATION -> LocationProvider.requestAuthorization()
        }
    }
}

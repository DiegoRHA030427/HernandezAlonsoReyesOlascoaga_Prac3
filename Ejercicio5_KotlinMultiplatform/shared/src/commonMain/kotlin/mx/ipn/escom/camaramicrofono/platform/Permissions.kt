package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable

/** Permisos de hardware que la app pide en tiempo de ejecución. */
enum class AppPermission { CAMERA, MICROPHONE, LOCATION }

@Stable
interface PermissionState {
    val isGranted: Boolean

    /** Muestra el diálogo del sistema para pedir el permiso. */
    fun request()
}

/**
 * Estado de un permiso (expect/actual):
 * - Android: `ActivityResultContracts.RequestMultiplePermissions` + `AndroidManifest.xml`.
 * - iOS: `AVCaptureDevice` / `AVAudioSession` / `CLLocationManager` + `Info.plist`.
 */
@Composable
expect fun rememberPermissionState(permission: AppPermission): PermissionState

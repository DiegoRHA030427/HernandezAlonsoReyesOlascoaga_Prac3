package mx.ipn.escom.camaramicrofono.platform

import androidx.compose.runtime.Composable
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.useContents
import kotlinx.coroutines.delay
import mx.ipn.escom.camaramicrofono.domain.GeoPoint
import platform.CoreLocation.*
import platform.Foundation.*
import platform.UIKit.*

/**
 * Ubicación con CLLocationManager (igual que LocationHelper del Ejercicio 3): opcional y
 * no bloqueante. Usa el GPS, así que funciona sin internet.
 */
@OptIn(ExperimentalForeignApi::class)
actual object LocationProvider {
    private val manager by lazy { CLLocationManager() }

    fun isAuthorized(): Boolean {
        val status = CLLocationManager.authorizationStatus()
        return status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways
    }

    fun requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    actual suspend fun currentLocation(): GeoPoint? {
        if (!isAuthorized()) {
            if (CLLocationManager.authorizationStatus() == kCLAuthorizationStatusNotDetermined) requestAuthorization()
            return null
        }
        manager.startUpdatingLocation()
        try {
            // Espera hasta ~2.5 s a que haya un "fix" (el llamador aplica además un timeout de 3 s).
            repeat(10) {
                manager.location?.let { location ->
                    return location.coordinate.useContents { GeoPoint(latitude, longitude) }
                }
                delay(250)
            }
            return null
        } finally {
            manager.stopUpdatingLocation()
        }
    }
}

/** Hoja de compartir del sistema (UIActivityViewController), igual que el Ejercicio 3. */
actual object ShareHelper {
    actual fun share(path: String, mimeType: String) {
        val presenter = topViewController() ?: return
        val controller = UIActivityViewController(
            activityItems = listOf(NSURL.fileURLWithPath(path)),
            applicationActivities = null,
        )
        // En iPad la hoja se muestra como popover y necesita una vista de origen.
        controller.popoverPresentationController?.sourceView = presenter.view
        presenter.presentViewController(controller, animated = true, completion = null)
    }
}

/** iOS no tiene botón "atrás" del sistema; la navegación se hace con los botones de la app. */
@Composable
actual fun PlatformBackHandler(enabled: Boolean, onBack: () -> Unit) {
}

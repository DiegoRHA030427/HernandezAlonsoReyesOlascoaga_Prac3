package mx.ipn.escom.camaramicrofono.platform

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner

/**
 * Permisos en tiempo de ejecución con Activity Result API. Los permisos se declaran
 * en `androidApp/src/main/AndroidManifest.xml` (equivalente a las claves de Info.plist).
 */
@Composable
actual fun rememberPermissionState(permission: AppPermission): PermissionState {
    val context = LocalContext.current
    val manifestPermissions = remember(permission) { permission.toManifest() }
    val state = remember(permission) { AndroidPermissionState(isGranted(context, manifestPermissions)) }

    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { result ->
        state.granted = result.values.any { it } || isGranted(context, manifestPermissions)
    }
    state.launch = { launcher.launch(manifestPermissions) }

    // Si el usuario concede el permiso desde Ajustes del sistema, se detecta al volver a la app.
    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner, permission) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) state.granted = isGranted(context, manifestPermissions)
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }
    return state
}

private class AndroidPermissionState(initial: Boolean) : PermissionState {
    var granted by mutableStateOf(initial)
    var launch: () -> Unit = {}

    override val isGranted: Boolean get() = granted

    override fun request() = launch()
}

private fun AppPermission.toManifest(): Array<String> = when (this) {
    AppPermission.CAMERA -> arrayOf(Manifest.permission.CAMERA)
    AppPermission.MICROPHONE -> arrayOf(Manifest.permission.RECORD_AUDIO)
    AppPermission.LOCATION -> arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
}

private fun isGranted(context: Context, permissions: Array<String>): Boolean =
    permissions.any { ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED }

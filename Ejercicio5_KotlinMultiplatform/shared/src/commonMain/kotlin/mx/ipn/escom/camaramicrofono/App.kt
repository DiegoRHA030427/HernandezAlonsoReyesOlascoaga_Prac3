package mx.ipn.escom.camaramicrofono

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.PhotoLibrary
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import mx.ipn.escom.camaramicrofono.di.AppContainer
import mx.ipn.escom.camaramicrofono.domain.AppSettings
import mx.ipn.escom.camaramicrofono.ui.audio.AudioScreen
import mx.ipn.escom.camaramicrofono.ui.camera.CameraScreen
import mx.ipn.escom.camaramicrofono.ui.gallery.GalleryScreen
import mx.ipn.escom.camaramicrofono.ui.settings.SettingsScreen
import mx.ipn.escom.camaramicrofono.ui.theme.CamaraMicrofonoTheme

private enum class Tab(val label: String, val selectedIcon: ImageVector, val icon: ImageVector) {
    CAMARA("Cámara", Icons.Filled.PhotoCamera, Icons.Outlined.PhotoCamera),
    AUDIO("Audio", Icons.Filled.Mic, Icons.Outlined.Mic),
    GALERIA("Galería", Icons.Filled.PhotoLibrary, Icons.Outlined.PhotoLibrary),
    AJUSTES("Ajustes", Icons.Filled.Settings, Icons.Outlined.Settings),
}

/**
 * Punto de entrada de la interfaz compartida por Android e iOS: cuatro pestañas
 * Cámara / Audio / Galería / Ajustes (igual que RootTabView del Ejercicio 3).
 */
@Composable
fun App() {
    val settings by AppContainer.settings.settings.collectAsState(initial = AppSettings())

    CamaraMicrofonoTheme(theme = settings.theme, appearance = settings.appearance) {
        var tabIndex by rememberSaveable { mutableIntStateOf(0) }
        val tab = Tab.entries[tabIndex]

        Scaffold(
            contentWindowInsets = WindowInsets(0, 0, 0, 0),
            bottomBar = {
                NavigationBar {
                    Tab.entries.forEachIndexed { index, item ->
                        NavigationBarItem(
                            selected = index == tabIndex,
                            onClick = { tabIndex = index },
                            icon = { Icon(if (index == tabIndex) item.selectedIcon else item.icon, contentDescription = null) },
                            label = { Text(item.label) },
                        )
                    }
                }
            },
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                when (tab) {
                    Tab.CAMARA -> CameraScreen(AppContainer.media, settings.defaultAlbum)
                    Tab.AUDIO -> AudioScreen(AppContainer.media, settings.defaultAlbum)
                    Tab.GALERIA -> GalleryScreen(AppContainer.media)
                    Tab.AJUSTES -> SettingsScreen(settings, AppContainer.settings)
                }
            }
        }
    }
}

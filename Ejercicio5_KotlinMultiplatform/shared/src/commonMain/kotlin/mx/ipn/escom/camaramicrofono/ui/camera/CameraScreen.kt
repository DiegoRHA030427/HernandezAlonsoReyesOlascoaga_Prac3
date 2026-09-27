package mx.ipn.escom.camaramicrofono.ui.camera

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.FlashOff
import androidx.compose.material.icons.filled.FlashOn
import androidx.compose.material.icons.filled.NoPhotography
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import mx.ipn.escom.camaramicrofono.data.MediaRepository
import mx.ipn.escom.camaramicrofono.di.AppContainer
import mx.ipn.escom.camaramicrofono.domain.PhotoFilter
import mx.ipn.escom.camaramicrofono.platform.AppPermission
import mx.ipn.escom.camaramicrofono.platform.ImageProcessor
import mx.ipn.escom.camaramicrofono.platform.LocationProvider
import mx.ipn.escom.camaramicrofono.platform.rememberCameraController
import mx.ipn.escom.camaramicrofono.platform.rememberPermissionState
import mx.ipn.escom.camaramicrofono.ui.components.MessageState
import mx.ipn.escom.camaramicrofono.ui.components.SaveToAlbumDialog
import mx.ipn.escom.camaramicrofono.ui.theme.appTopBarColors

private val TIMER_OPTIONS = listOf(0, 3, 5, 10)

/** Pantalla de captura de fotos (equivalente a CameraCaptureView del Ejercicio 3). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CameraScreen(media: MediaRepository, defaultAlbum: String) {
    val camera = rememberCameraController()
    val cameraPermission = rememberPermissionState(AppPermission.CAMERA)
    val locationPermission = rememberPermissionState(AppPermission.LOCATION)
    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }

    var flashOn by remember { mutableStateOf(false) }
    var filter by remember { mutableStateOf(PhotoFilter.NINGUNO) }
    var timerSeconds by remember { mutableIntStateOf(0) }
    var countdown by remember { mutableStateOf<Int?>(null) }
    var busy by remember { mutableStateOf(false) }
    var pendingPhoto by remember { mutableStateOf<ByteArray?>(null) }
    var message by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(message) {
        message?.let {
            snackbar.showSnackbar(it)
            message = null
        }
    }

    // Dispara la captura respetando el temporizador configurado.
    fun shoot() {
        if (busy) return
        busy = true
        scope.launch {
            for (second in timerSeconds downTo 1) {
                countdown = second
                delay(1_000)
            }
            countdown = null
            camera.takePicture(flashOn) { bytes ->
                scope.launch {
                    if (bytes == null) {
                        busy = false
                        return@launch
                    }
                    pendingPhoto = withContext(Dispatchers.Default) { ImageProcessor.applyFilter(bytes, filter) }
                    busy = false
                }
            }
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = {
            TopAppBar(
                title = { Text("Cámara") },
                colors = appTopBarColors(),
                actions = {
                    if (cameraPermission.isGranted) {
                        IconButton(onClick = { flashOn = !flashOn }) {
                            Icon(
                                if (flashOn) Icons.Filled.FlashOn else Icons.Filled.FlashOff,
                                contentDescription = if (flashOn) "Flash activado" else "Flash desactivado",
                            )
                        }
                    }
                },
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when {
                !cameraPermission.isGranted -> MessageState(
                    icon = Icons.Filled.NoPhotography,
                    message = "Se necesita acceso a la cámara para tomar fotos.",
                    actionLabel = "Permitir cámara",
                    onAction = cameraPermission::request,
                )

                camera.hasLivePreview -> camera.Preview(Modifier.fillMaxSize())

                else -> MessageState(
                    icon = Icons.Filled.PhotoCamera,
                    message = "Al tocar el botón se abre la cámara del sistema.\n" +
                        "En el simulador (sin cámara física) se abre la fototeca como alternativa.",
                )
            }

            countdown?.let {
                Text(
                    "$it",
                    modifier = Modifier.align(Alignment.Center),
                    color = Color.White,
                    fontSize = 96.sp,
                    fontWeight = FontWeight.Bold,
                    style = TextStyle(shadow = Shadow(color = Color.Black, blurRadius = 16f)),
                )
            }

            if (cameraPermission.isGranted) {
                ControlsBar(
                    filter = filter,
                    onFilter = { filter = it },
                    timerSeconds = timerSeconds,
                    onTimer = { timerSeconds = it },
                    enabled = !busy,
                    onShutter = ::shoot,
                    modifier = Modifier.align(Alignment.BottomCenter),
                )
            }
        }
    }

    pendingPhoto?.let { photo ->
        val preview = remember(photo) { ImageProcessor.decode(ImageProcessor.thumbnail(photo, 900)) }
        SaveToAlbumDialog(
            title = "Guardar foto",
            initialAlbum = defaultAlbum,
            onDiscard = { pendingPhoto = null },
            onSave = { album ->
                pendingPhoto = null
                AppContainer.appScope.launch {
                    // Ubicación opcional y no bloqueante (máx. 3 s), como el Ejercicio 3.
                    val location = if (locationPermission.isGranted) {
                        withTimeoutOrNull(3_000) { LocationProvider.currentLocation() }
                    } else {
                        locationPermission.request()
                        null
                    }
                    val saved = media.savePhoto(photo, album, location)
                    message = if (saved != null) "Foto guardada en «${saved.albumName}»" else "No se pudo guardar la foto."
                }
            },
        ) {
            if (preview != null) {
                Image(
                    bitmap = preview,
                    contentDescription = "Vista previa",
                    contentScale = ContentScale.Fit,
                    modifier = Modifier.fillMaxWidth().heightIn(max = 280.dp).clip(RoundedCornerShape(12.dp)),
                )
            }
        }
    }
}

/** Filtros, temporizador y botón de disparo (sobre la vista previa). */
@Composable
private fun ControlsBar(
    filter: PhotoFilter,
    onFilter: (PhotoFilter) -> Unit,
    timerSeconds: Int,
    onTimer: (Int) -> Unit,
    enabled: Boolean,
    onShutter: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(
        modifier = modifier.fillMaxWidth(),
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.88f),
    ) {
        Column(
            modifier = Modifier.padding(vertical = 12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                PhotoFilter.entries.forEach { option ->
                    FilterChip(
                        selected = option == filter,
                        onClick = { onFilter(option) },
                        label = { Text(option.label) },
                    )
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TIMER_OPTIONS.forEach { seconds ->
                    FilterChip(
                        selected = seconds == timerSeconds,
                        onClick = { onTimer(seconds) },
                        label = { Text(if (seconds == 0) "Sin temporizador" else "$seconds s") },
                    )
                }
            }
            val ringColor = MaterialTheme.colorScheme.primary
            Box(
                modifier = Modifier
                    .size(76.dp)
                    .border(BorderStroke(4.dp, ringColor), CircleShape)
                    .padding(8.dp)
                    .clip(CircleShape)
                    .background(if (enabled) ringColor else ringColor.copy(alpha = 0.4f))
                    .clickable(enabled = enabled, onClick = onShutter),
                contentAlignment = Alignment.Center,
            ) {
                Icon(Icons.Filled.PhotoCamera, contentDescription = "Tomar foto", tint = MaterialTheme.colorScheme.onPrimary)
            }
        }
    }
}

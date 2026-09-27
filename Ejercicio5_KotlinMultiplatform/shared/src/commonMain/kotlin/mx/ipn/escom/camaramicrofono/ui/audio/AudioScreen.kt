package mx.ipn.escom.camaramicrofono.ui.audio

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import mx.ipn.escom.camaramicrofono.data.MediaRepository
import mx.ipn.escom.camaramicrofono.di.AppContainer
import mx.ipn.escom.camaramicrofono.platform.AppPermission
import mx.ipn.escom.camaramicrofono.platform.AudioRecorder
import mx.ipn.escom.camaramicrofono.platform.FileStorage
import mx.ipn.escom.camaramicrofono.platform.currentTimeMillis
import mx.ipn.escom.camaramicrofono.platform.rememberPermissionState
import mx.ipn.escom.camaramicrofono.ui.components.MessageState
import mx.ipn.escom.camaramicrofono.ui.components.SaveToAlbumDialog
import mx.ipn.escom.camaramicrofono.ui.theme.appTopBarColors
import mx.ipn.escom.camaramicrofono.util.WavWriter
import mx.ipn.escom.camaramicrofono.util.formatDuration
import kotlin.math.abs
import kotlin.math.sin
import kotlin.time.TimeSource

/** Opciones del temporizador de grabación (duración máxima). 0 = sin límite. */
private val MAX_DURATION_OPTIONS = listOf(0, 15, 30, 60)

private data class PendingRecording(val path: String, val durationSeconds: Double)

/**
 * Grabadora de audio (equivalente a AudioRecorderView del Ejercicio 3): medidor de nivel,
 * "sensibilidad" del micrófono y temporizador de grabación (duración máxima).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AudioScreen(media: MediaRepository, defaultAlbum: String) {
    val micPermission = rememberPermissionState(AppPermission.MICROPHONE)
    val recorder = remember { AudioRecorder() }
    DisposableEffect(Unit) { onDispose { recorder.release() } }

    val scope = rememberCoroutineScope()
    val snackbar = remember { SnackbarHostState() }
    var message by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(message) {
        message?.let {
            snackbar.showSnackbar(it)
            message = null
        }
    }

    var isRecording by remember { mutableStateOf(false) }
    var isFallback by remember { mutableStateOf(false) }
    var recordingPath by remember { mutableStateOf<String?>(null) }
    var elapsed by remember { mutableDoubleStateOf(0.0) }
    var level by remember { mutableFloatStateOf(0f) }
    var sensitivity by remember { mutableFloatStateOf(0.5f) }
    var maxDuration by remember { mutableIntStateOf(0) }
    var pending by remember { mutableStateOf<PendingRecording?>(null) }

    fun startRecording() {
        val baseName = "REC_${currentTimeMillis()}"
        val path = FileStorage.tempPath("$baseName.${recorder.fileExtension}")
        recorder.setGain(sensitivity)
        if (recorder.start(path)) {
            isFallback = false
            recordingPath = path
        } else {
            // Sin micrófono (p. ej. emulador o VM sin audio): se simula la grabación y al
            // detenerla se genera un WAV silencioso con la misma duración, como el Ejercicio 3.
            isFallback = true
            recordingPath = FileStorage.tempPath("$baseName.wav")
            message = "No hay micrófono disponible: se generará un audio de respaldo (silencioso)."
        }
        elapsed = 0.0
        isRecording = true
    }

    fun stopRecording() {
        if (!isRecording) return
        isRecording = false
        level = 0f
        val path = recordingPath ?: return
        if (isFallback) {
            FileStorage.writeBytes(path, WavWriter.silence(maxOf(elapsed, 1.0)))
        } else {
            recorder.stop()
        }
        pending = PendingRecording(path, elapsed)
    }

    // Cronómetro + medidor de nivel mientras se graba.
    LaunchedEffect(isRecording) {
        if (!isRecording) return@LaunchedEffect
        val start = TimeSource.Monotonic.markNow()
        while (isActive && isRecording) {
            elapsed = start.elapsedNow().inWholeMilliseconds / 1000.0
            level = if (isFallback) (0.3 + 0.3 * abs(sin(elapsed * 3))).toFloat() else recorder.level()
            if (maxDuration > 0 && elapsed >= maxDuration) {
                stopRecording()
                break
            }
            delay(100)
        }
    }

    val pulse by animateFloatAsState(targetValue = 1f + level * 0.3f, animationSpec = tween(100))

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        snackbarHost = { SnackbarHost(snackbar) },
        topBar = { TopAppBar(title = { Text("Audio") }, colors = appTopBarColors()) },
    ) { padding ->
        if (!micPermission.isGranted) {
            MessageState(
                icon = Icons.Filled.MicOff,
                message = "Se necesita acceso al micrófono para grabar.",
                actionLabel = "Permitir micrófono",
                onAction = micPermission::request,
                modifier = Modifier.padding(padding),
            )
            return@Scaffold
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 24.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            val primary = MaterialTheme.colorScheme.primary
            Box(contentAlignment = Alignment.Center, modifier = Modifier.size(240.dp)) {
                Box(
                    Modifier
                        .size(200.dp)
                        .scale(pulse)
                        .clip(CircleShape)
                        .background(primary.copy(alpha = 0.15f)),
                )
                Icon(
                    if (isRecording) Icons.Filled.GraphicEq else Icons.Filled.Mic,
                    contentDescription = null,
                    tint = primary,
                    modifier = Modifier.size(64.dp),
                )
            }

            Text(
                formatDuration(elapsed),
                style = MaterialTheme.typography.headlineMedium,
                fontFamily = FontFamily.Monospace,
            )

            // Botón grabar / detener
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .clip(CircleShape)
                    .background(if (isRecording) Color(0xFFD32F2F) else primary)
                    .clickable { if (isRecording) stopRecording() else startRecording() },
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    if (isRecording) Icons.Filled.Stop else Icons.Filled.Mic,
                    contentDescription = if (isRecording) "Detener" else "Grabar",
                    tint = Color.White,
                    modifier = Modifier.size(36.dp),
                )
            }

            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    "Sensibilidad del micrófono",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                if (recorder.isGainAdjustable) {
                    Slider(
                        value = sensitivity,
                        onValueChange = {
                            sensitivity = it
                            recorder.setGain(it)
                        },
                        enabled = !isRecording,
                    )
                } else {
                    Text(
                        "Este dispositivo no permite ajustar la ganancia de entrada; se usa el nivel automático del sistema.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }

                Spacer(Modifier.height(8.dp))
                Text(
                    "Temporizador de grabación",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    MAX_DURATION_OPTIONS.forEachIndexed { index, seconds ->
                        SegmentedButton(
                            selected = seconds == maxDuration,
                            onClick = { maxDuration = seconds },
                            enabled = !isRecording,
                            shape = SegmentedButtonDefaults.itemShape(index = index, count = MAX_DURATION_OPTIONS.size),
                        ) {
                            Text(if (seconds == 0) "Sin límite" else "$seconds s")
                        }
                    }
                }
            }

            Text(
                "Todo se guarda en el dispositivo; no se necesita internet.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
    }

    pending?.let { recording ->
        SaveToAlbumDialog(
            title = "Guardar audio",
            initialAlbum = defaultAlbum,
            onDiscard = {
                FileStorage.delete(recording.path)
                pending = null
            },
            onSave = { album ->
                pending = null
                AppContainer.appScope.launch {
                    val saved = media.saveAudio(recording.path, recording.durationSeconds, album)
                    message = if (saved != null) "Audio guardado en «${saved.albumName}»" else "No se pudo guardar el audio."
                }
            },
        ) {
            Text("Grabación de ${recording.durationSeconds.toInt()} segundos")
        }
    }
}

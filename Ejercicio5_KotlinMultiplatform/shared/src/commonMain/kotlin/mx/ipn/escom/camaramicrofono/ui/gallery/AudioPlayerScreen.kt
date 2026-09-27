package mx.ipn.escom.camaramicrofono.ui.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.FilledIconButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import mx.ipn.escom.camaramicrofono.data.MediaRepository
import mx.ipn.escom.camaramicrofono.domain.MediaItem
import mx.ipn.escom.camaramicrofono.platform.AudioPlayer
import mx.ipn.escom.camaramicrofono.platform.ShareHelper
import mx.ipn.escom.camaramicrofono.util.formatDuration

/** Reproductor de audios guardados (equivalente a AudioPlayerView del Ejercicio 3). */
@Composable
fun AudioPlayerScreen(item: MediaItem, media: MediaRepository, onClose: () -> Unit) {
    val scope = rememberCoroutineScope()
    val player = remember(item.id) { AudioPlayer() }
    var loaded by remember(item.id) { mutableStateOf(false) }
    var isPlaying by remember(item.id) { mutableStateOf(false) }
    var position by remember(item.id) { mutableDoubleStateOf(0.0) }
    var duration by remember(item.id) { mutableDoubleStateOf(item.durationSeconds) }

    DisposableEffect(item.id) {
        loaded = player.load(media.pathOf(item))
        if (loaded && player.durationSeconds > 0) duration = player.durationSeconds
        onDispose { player.release() }
    }

    // Progreso de reproducción.
    LaunchedEffect(isPlaying) {
        while (isActive && isPlaying) {
            position = player.positionSeconds
            if (!player.isPlaying) {
                isPlaying = false
                position = 0.0
            }
            delay(200)
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            DetailTopBar(
                title = "Audio",
                onClose = onClose,
                onShare = { ShareHelper.share(media.pathOf(item), item.mimeType) },
                onDelete = {
                    scope.launch {
                        player.release()
                        media.delete(item)
                        onClose()
                    }
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(Modifier.size(140.dp), contentAlignment = Alignment.Center) {
                Icon(
                    Icons.Filled.GraphicEq,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(96.dp),
                )
            }

            if (!loaded) {
                Text("No se pudo abrir el archivo de audio.", color = MaterialTheme.colorScheme.error)
            }

            val maxPosition = duration.toFloat().coerceAtLeast(0.1f)
            Slider(
                value = position.toFloat().coerceIn(0f, maxPosition),
                onValueChange = {
                    position = it.toDouble()
                    player.seekTo(position)
                },
                valueRange = 0f..maxPosition,
                enabled = loaded,
                modifier = Modifier.fillMaxWidth(),
            )
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(formatDuration(position), fontFamily = FontFamily.Monospace)
                Text(formatDuration(duration), fontFamily = FontFamily.Monospace)
            }

            FilledIconButton(
                onClick = {
                    if (isPlaying) {
                        player.pause()
                        isPlaying = false
                    } else {
                        player.play()
                        isPlaying = true
                    }
                },
                enabled = loaded,
                modifier = Modifier.size(72.dp),
            ) {
                Icon(
                    if (isPlaying) Icons.Filled.Pause else Icons.Filled.PlayArrow,
                    contentDescription = if (isPlaying) "Pausar" else "Reproducir",
                    modifier = Modifier.size(40.dp),
                )
            }

            OutlinedButton(onClick = { media.setFavorite(item, !item.isFavorite) }) {
                Icon(
                    if (item.isFavorite) Icons.Filled.Star else Icons.Filled.StarBorder,
                    contentDescription = null,
                    tint = if (item.isFavorite) Color(0xFFFFC107) else MaterialTheme.colorScheme.primary,
                )
                Text(if (item.isFavorite) "  Favorito" else "  Marcar como favorito")
            }

            MetadataCard(item)
            AlbumTagsEditor(item) { album, tags -> media.updateAlbumAndTags(item, album, tags) }
        }
    }
}

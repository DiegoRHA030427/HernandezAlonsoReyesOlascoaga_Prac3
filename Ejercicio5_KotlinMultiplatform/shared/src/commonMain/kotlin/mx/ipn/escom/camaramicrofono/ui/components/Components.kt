package mx.ipn.escom.camaramicrofono.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import mx.ipn.escom.camaramicrofono.platform.FileStorage
import mx.ipn.escom.camaramicrofono.platform.ImageProcessor
import mx.ipn.escom.camaramicrofono.util.ThumbnailCache

/** Mensaje centrado con ícono y botón opcional (equivalente a ContentUnavailableFallback). */
@Composable
fun MessageState(
    icon: ImageVector,
    message: String,
    modifier: Modifier = Modifier,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Column(
        modifier = modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, contentDescription = null, modifier = Modifier.size(56.dp), tint = MaterialTheme.colorScheme.primary)
        Text(
            message,
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (actionLabel != null && onAction != null) {
            Button(onClick = onAction) { Text(actionLabel) }
        }
    }
}

/**
 * Carga una foto guardada como [ImageBitmap] en segundo plano, reducida a [maxSize] px,
 * y la guarda en [ThumbnailCache] para que la galería cargue rápido.
 */
@Composable
fun rememberStoredImage(fileName: String, maxSize: Int): ImageBitmap? {
    val key = "$fileName#$maxSize"
    val revision = ThumbnailCache.revision
    var image by remember(key, revision) { mutableStateOf(ThumbnailCache.get(key)) }
    LaunchedEffect(key, revision) {
        if (image == null) {
            val decoded = withContext(Dispatchers.Default) {
                FileStorage.readBytes(FileStorage.mediaPath(fileName))
                    ?.let { ImageProcessor.thumbnail(it, maxSize) }
                    ?.let { ImageProcessor.decode(it) }
            }
            if (decoded != null) {
                ThumbnailCache.put(key, decoded)
                image = decoded
            }
        }
    }
    return image
}

/**
 * Diálogo para confirmar en qué álbum guardar una captura
 * (equivalente a SaveCapturedPhotoSheet / SaveRecordingSheet del Ejercicio 3).
 */
@Composable
fun SaveToAlbumDialog(
    title: String,
    initialAlbum: String,
    onSave: (String) -> Unit,
    onDiscard: () -> Unit,
    preview: @Composable () -> Unit,
) {
    var album by remember { mutableStateOf(initialAlbum) }
    AlertDialog(
        onDismissRequest = onDiscard,
        title = { Text(title) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                preview()
                OutlinedTextField(
                    value = album,
                    onValueChange = { album = it },
                    label = { Text("Álbum / categoría") },
                    singleLine = true,
                )
            }
        },
        confirmButton = { TextButton(onClick = { onSave(album) }) { Text("Guardar") } },
        dismissButton = {
            TextButton(onClick = onDiscard) {
                Text("Descartar", color = MaterialTheme.colorScheme.error)
            }
        },
    )
}

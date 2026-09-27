package mx.ipn.escom.camaramicrofono.ui.gallery

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import mx.ipn.escom.camaramicrofono.domain.MediaItem
import mx.ipn.escom.camaramicrofono.platform.formatDateTime
import mx.ipn.escom.camaramicrofono.ui.theme.appTopBarColors
import mx.ipn.escom.camaramicrofono.util.formatCoordinates
import mx.ipn.escom.camaramicrofono.util.formatDuration

/** Barra superior común de los detalles: cerrar, compartir y eliminar (con confirmación). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun DetailTopBar(title: String, onClose: () -> Unit, onShare: () -> Unit, onDelete: () -> Unit) {
    var confirmDelete by remember { mutableStateOf(false) }
    TopAppBar(
        title = { Text(title) },
        colors = appTopBarColors(),
        navigationIcon = {
            IconButton(onClick = onClose) { Icon(Icons.Filled.Close, contentDescription = "Cerrar") }
        },
        actions = {
            IconButton(onClick = onShare) { Icon(Icons.Filled.Share, contentDescription = "Compartir") }
            IconButton(onClick = { confirmDelete = true }) { Icon(Icons.Filled.Delete, contentDescription = "Eliminar") }
        },
    )
    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Eliminar") },
            text = { Text("¿Seguro que quieres eliminar este elemento? Esta acción no se puede deshacer.") },
            confirmButton = {
                TextButton(onClick = {
                    confirmDelete = false
                    onDelete()
                }) { Text("Eliminar", color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("Cancelar") } },
        )
    }
}

/** Metadatos guardados en SQLDelight: fecha, ubicación, duración. */
@Composable
internal fun MetadataCard(item: MediaItem) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            MetadataRow("Fecha", formatDateTime(item.dateCreated))
            MetadataRow(
                "Ubicación",
                item.location?.let { formatCoordinates(it.latitude, it.longitude) } ?: "Sin ubicación",
            )
            if (item.isAudio) MetadataRow("Duración", formatDuration(item.durationSeconds))
            MetadataRow("Archivo", item.fileName)
        }
    }
}

@Composable
private fun MetadataRow(label: String, value: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("$label:", style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.SemiBold)
        Text(value, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

/** Álbum y etiquetas editables (organizar en categorías, como el Ejercicio 3). */
@Composable
internal fun AlbumTagsEditor(item: MediaItem, onSave: (album: String, tags: String) -> Unit) {
    var album by remember(item.id) { mutableStateOf(item.albumName) }
    var tags by remember(item.id) { mutableStateOf(item.tags) }
    val changed = album.trim() != item.albumName || tags.trim() != item.tags
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        OutlinedTextField(
            value = album,
            onValueChange = { album = it },
            label = { Text("Álbum / categoría") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = tags,
            onValueChange = { tags = it },
            label = { Text("Etiquetas (separadas por comas)") },
            singleLine = true,
            modifier = Modifier.fillMaxWidth(),
        )
        Button(onClick = { onSave(album, tags) }, enabled = changed, modifier = Modifier.fillMaxWidth()) {
            Text("Guardar álbum y etiquetas")
        }
    }
}

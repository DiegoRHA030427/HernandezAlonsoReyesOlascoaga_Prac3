package mx.ipn.escom.camaramicrofono.ui.gallery

import androidx.compose.foundation.Image
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Rotate90DegreesCw
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material3.AssistChip
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import mx.ipn.escom.camaramicrofono.data.MediaRepository
import mx.ipn.escom.camaramicrofono.domain.MediaItem
import mx.ipn.escom.camaramicrofono.domain.PhotoFilter
import mx.ipn.escom.camaramicrofono.platform.FileStorage
import mx.ipn.escom.camaramicrofono.platform.ImageProcessor
import mx.ipn.escom.camaramicrofono.platform.ShareHelper
import mx.ipn.escom.camaramicrofono.ui.components.rememberStoredImage

/**
 * Visor de fotos con edición básica (equivalente a PhotoDetailView del Ejercicio 3):
 * rotar, reaplicar filtro, favoritos, álbum/etiquetas, compartir y eliminar.
 */
@Composable
fun PhotoDetailScreen(item: MediaItem, media: MediaRepository, onClose: () -> Unit) {
    val scope = rememberCoroutineScope()
    var working by remember { mutableStateOf(false) }
    val image = rememberStoredImage(item.fileName, maxSize = 1600)

    // Lee la foto, la transforma en segundo plano y la vuelve a guardar.
    fun edit(transform: (ByteArray) -> ByteArray) {
        if (working) return
        working = true
        scope.launch {
            val bytes = withContext(Dispatchers.Default) {
                FileStorage.readBytes(media.pathOf(item))?.let(transform)
            }
            if (bytes != null) media.overwritePhoto(item, bytes)
            working = false
        }
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            DetailTopBar(
                title = "Foto",
                onClose = onClose,
                onShare = { ShareHelper.share(media.pathOf(item), item.mimeType) },
                onDelete = {
                    scope.launch {
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
        ) {
            Box(
                modifier = Modifier.fillMaxWidth().heightIn(min = 200.dp, max = 380.dp),
                contentAlignment = Alignment.Center,
            ) {
                if (image != null) {
                    Image(
                        bitmap = image,
                        contentDescription = item.fileName,
                        contentScale = ContentScale.Fit,
                        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)),
                    )
                }
                if (image == null || working) CircularProgressIndicator()
            }

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedButton(onClick = { edit { ImageProcessor.rotate(it, 90) } }, enabled = !working) {
                    Icon(Icons.Filled.Rotate90DegreesCw, contentDescription = null)
                    Text("  Rotar")
                }
                OutlinedButton(onClick = { media.setFavorite(item, !item.isFavorite) }) {
                    Icon(
                        if (item.isFavorite) Icons.Filled.Star else Icons.Filled.StarBorder,
                        contentDescription = null,
                        tint = if (item.isFavorite) Color(0xFFFFC107) else MaterialTheme.colorScheme.primary,
                    )
                    Text(if (item.isFavorite) "  Favorito" else "  Marcar")
                }
            }

            Text("Aplicar filtro", style = MaterialTheme.typography.labelLarge)
            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                PhotoFilter.entries.filter { it != PhotoFilter.NINGUNO }.forEach { filter ->
                    AssistChip(
                        onClick = { edit { ImageProcessor.applyFilter(it, filter) } },
                        label = { Text(filter.label) },
                        enabled = !working,
                    )
                }
            }

            MetadataCard(item)
            AlbumTagsEditor(item) { album, tags -> media.updateAlbumAndTags(item, album, tags) }
            Spacer(Modifier.height(8.dp))
        }
    }
}

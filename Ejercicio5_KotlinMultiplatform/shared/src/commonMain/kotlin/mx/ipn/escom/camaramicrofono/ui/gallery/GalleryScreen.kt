package mx.ipn.escom.camaramicrofono.ui.gallery

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.PhotoLibrary
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import mx.ipn.escom.camaramicrofono.data.MediaRepository
import mx.ipn.escom.camaramicrofono.domain.MediaItem
import mx.ipn.escom.camaramicrofono.platform.PlatformBackHandler
import mx.ipn.escom.camaramicrofono.ui.components.MessageState
import mx.ipn.escom.camaramicrofono.ui.components.rememberStoredImage
import mx.ipn.escom.camaramicrofono.ui.theme.appTopBarColors
import mx.ipn.escom.camaramicrofono.util.albumFilterOptions
import mx.ipn.escom.camaramicrofono.util.formatDuration

private const val ALL_ALBUMS = "Todos"

/**
 * Galería integrada (equivalente a GalleryView del Ejercicio 3): fotos y audios guardados,
 * filtrables por álbum, con miniaturas cacheadas.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GalleryScreen(media: MediaRepository) {
    val items by media.items.collectAsState(initial = emptyList())
    var selectedAlbum by rememberSaveable { mutableStateOf(ALL_ALBUMS) }
    var selectedId by rememberSaveable { mutableStateOf<String?>(null) }
    var menuOpen by remember { mutableStateOf(false) }

    val selected = items.firstOrNull { it.id == selectedId }
    if (selected != null) {
        PlatformBackHandler { selectedId = null }
        if (selected.isPhoto) {
            PhotoDetailScreen(selected, media, onClose = { selectedId = null })
        } else {
            AudioPlayerScreen(selected, media, onClose = { selectedId = null })
        }
        return
    }

    val albums = albumFilterOptions(items.map { it.albumName }, ALL_ALBUMS)
    val visible = if (selectedAlbum == ALL_ALBUMS) items else items.filter { it.albumName == selectedAlbum }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = {
            TopAppBar(
                title = { Text("Galería") },
                colors = appTopBarColors(),
                actions = {
                    Box {
                        TextButton(onClick = { menuOpen = true }) {
                            Text(selectedAlbum, color = appTopBarColors().actionIconContentColor)
                            Icon(
                                Icons.Filled.ArrowDropDown,
                                contentDescription = "Elegir álbum",
                                tint = appTopBarColors().actionIconContentColor,
                            )
                        }
                        DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                            albums.forEach { album ->
                                DropdownMenuItem(
                                    text = { Text(album) },
                                    onClick = {
                                        selectedAlbum = album
                                        menuOpen = false
                                    },
                                )
                            }
                        }
                    }
                },
            )
        },
    ) { padding ->
        if (visible.isEmpty()) {
            MessageState(
                icon = Icons.Filled.PhotoLibrary,
                message = if (items.isEmpty()) {
                    "Todavía no has capturado fotos ni audios.\nUsa las pestañas Cámara o Audio para empezar."
                } else {
                    "No hay elementos en el álbum «$selectedAlbum»."
                },
                modifier = Modifier.padding(padding),
            )
        } else {
            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 104.dp),
                modifier = Modifier.fillMaxSize().padding(padding),
                contentPadding = PaddingValues(8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(visible, key = { it.id }) { item ->
                    GalleryCell(item, onClick = { selectedId = item.id })
                }
            }
        }
    }
}

@Composable
private fun GalleryCell(item: MediaItem, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .aspectRatio(1f)
            .clip(RoundedCornerShape(10.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        if (item.isPhoto) {
            val thumbnail = rememberStoredImage(item.fileName, maxSize = 320)
            if (thumbnail != null) {
                Image(
                    bitmap = thumbnail,
                    contentDescription = item.fileName,
                    contentScale = ContentScale.Crop,
                    modifier = Modifier.fillMaxSize(),
                )
            }
        } else {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(
                    Icons.Filled.GraphicEq,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(36.dp),
                )
                Text(
                    formatDuration(item.durationSeconds),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
        if (item.isFavorite) {
            Icon(
                Icons.Filled.Star,
                contentDescription = "Favorito",
                tint = Color(0xFFFFC107),
                modifier = Modifier.align(Alignment.BottomStart).padding(4.dp).size(18.dp),
            )
        }
    }
}

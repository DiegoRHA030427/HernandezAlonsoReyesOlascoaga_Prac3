package mx.ipn.escom.camaramicrofono.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import mx.ipn.escom.camaramicrofono.data.SettingsRepository
import mx.ipn.escom.camaramicrofono.domain.AppSettings
import mx.ipn.escom.camaramicrofono.domain.AppThemeOption
import mx.ipn.escom.camaramicrofono.domain.AppearanceMode
import mx.ipn.escom.camaramicrofono.platform.platformName
import mx.ipn.escom.camaramicrofono.ui.theme.Azul
import mx.ipn.escom.camaramicrofono.ui.theme.Guinda
import mx.ipn.escom.camaramicrofono.ui.theme.appTopBarColors

/** Ajustes: tema, modo claro/oscuro y álbum por defecto (equivalente a SettingsView del Ejercicio 3). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(settings: AppSettings, repository: SettingsRepository) {
    var album by remember { mutableStateOf(settings.defaultAlbum) }
    // Sincroniza el campo cuando el valor guardado cambia desde la base de datos
    // (sin pisar lo que el usuario está escribiendo, p. ej. un espacio al final).
    LaunchedEffect(settings.defaultAlbum) {
        if (album.trim() != settings.defaultAlbum) album = settings.defaultAlbum
    }

    Scaffold(
        contentWindowInsets = WindowInsets(0, 0, 0, 0),
        topBar = { TopAppBar(title = { Text("Ajustes") }, colors = appTopBarColors()) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SectionTitle("Tema")
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                AppThemeOption.entries.forEachIndexed { index, theme ->
                    SegmentedButton(
                        selected = settings.theme == theme,
                        onClick = { repository.setTheme(theme) },
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = AppThemeOption.entries.size),
                        icon = {
                            Box(
                                Modifier
                                    .size(14.dp)
                                    .clip(CircleShape)
                                    .background(if (theme == AppThemeOption.GUINDA) Guinda else Azul),
                            )
                        },
                    ) { Text(theme.displayName) }
                }
            }

            SectionTitle("Modo claro / oscuro")
            SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                AppearanceMode.entries.forEachIndexed { index, mode ->
                    SegmentedButton(
                        selected = settings.appearance == mode,
                        onClick = { repository.setAppearance(mode) },
                        shape = SegmentedButtonDefaults.itemShape(index = index, count = AppearanceMode.entries.size),
                    ) { Text(mode.label) }
                }
            }
            Text(
                "Por defecto la app sigue el modo del sistema. Ambos temas tienen versión clara y oscura.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )

            SectionTitle("Preferencias")
            OutlinedTextField(
                value = album,
                onValueChange = {
                    album = it
                    if (it.isNotBlank()) repository.setDefaultAlbum(it)
                },
                label = { Text("Álbum por defecto") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )

            SectionTitle("Acerca de")
            Card(Modifier.fillMaxWidth()) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text("Cámara y Micrófono — Práctica 3, Ejercicio 5 (Kotlin Multiplatform)")
                    Text(
                        "IPN · ESCOM — Desarrollo de Aplicaciones Móviles Nativas",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Text(
                        "Funciona 100 % sin conexión: fotos y audios en el dispositivo, metadatos en SQLDelight.",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Text(
                        "Plataforma: $platformName",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.titleSmall,
        color = MaterialTheme.colorScheme.primary,
        modifier = Modifier.padding(top = 8.dp),
    )
}

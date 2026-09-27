package mx.ipn.escom.camaramicrofono.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TopAppBarColors
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import mx.ipn.escom.camaramicrofono.domain.AppThemeOption
import mx.ipn.escom.camaramicrofono.domain.AppearanceMode

// Colores institucionales: los mismos hex que AppTheme.swift (Ejercicios 2 y 3)
// y app_theme.dart (Ejercicio 4).
val Guinda = Color(0xFF9B023D)
val Azul = Color(0xFF003E80)

// Paletas tonales de Material 3 generadas a partir de cada color institucional.
// En modo claro el color primario es el institucional exacto; en modo oscuro se usa
// un tono más claro del mismo color para mantener buen contraste.
private val GuindaLight = lightColorScheme(
    primary = Guinda,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFFFD9DF),
    onPrimaryContainer = Color(0xFF3F0016),
    secondary = Color(0xFF75565C),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFFFD9DF),
    onSecondaryContainer = Color(0xFF2B151A),
    background = Color(0xFFFFF8F7),
    onBackground = Color(0xFF22191A),
    surface = Color(0xFFFFF8F7),
    onSurface = Color(0xFF22191A),
    surfaceVariant = Color(0xFFF3DDE0),
    onSurfaceVariant = Color(0xFF524345),
    outline = Color(0xFF847375),
)

private val GuindaDark = darkColorScheme(
    primary = Color(0xFFFFB1C1),
    onPrimary = Color(0xFF650027),
    primaryContainer = Color(0xFF8E0039),
    onPrimaryContainer = Color(0xFFFFD9DF),
    secondary = Color(0xFFE5BDC3),
    onSecondary = Color(0xFF43292E),
    secondaryContainer = Color(0xFF5C3F44),
    onSecondaryContainer = Color(0xFFFFD9DF),
    background = Color(0xFF191113),
    onBackground = Color(0xFFEFDFE0),
    surface = Color(0xFF191113),
    onSurface = Color(0xFFEFDFE0),
    surfaceVariant = Color(0xFF524345),
    onSurfaceVariant = Color(0xFFD6C2C4),
    outline = Color(0xFF9F8C8E),
)

private val AzulLight = lightColorScheme(
    primary = Azul,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD6E3FF),
    onPrimaryContainer = Color(0xFF001B3E),
    secondary = Color(0xFF555F71),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFD9E3F8),
    onSecondaryContainer = Color(0xFF121C2B),
    background = Color(0xFFF9F9FF),
    onBackground = Color(0xFF191C20),
    surface = Color(0xFFF9F9FF),
    onSurface = Color(0xFF191C20),
    surfaceVariant = Color(0xFFE0E2EC),
    onSurfaceVariant = Color(0xFF43474E),
    outline = Color(0xFF74777F),
)

private val AzulDark = darkColorScheme(
    primary = Color(0xFFA9C7FF),
    onPrimary = Color(0xFF003061),
    primaryContainer = Color(0xFF00468D),
    onPrimaryContainer = Color(0xFFD6E3FF),
    secondary = Color(0xFFBDC7DC),
    onSecondary = Color(0xFF273141),
    secondaryContainer = Color(0xFF3E4759),
    onSecondaryContainer = Color(0xFFD9E3F8),
    background = Color(0xFF111318),
    onBackground = Color(0xFFE2E2E9),
    surface = Color(0xFF111318),
    onSurface = Color(0xFFE2E2E9),
    surfaceVariant = Color(0xFF43474E),
    onSurfaceVariant = Color(0xFFC3C6CF),
    outline = Color(0xFF8D9199),
)

/** true si el tema actual es oscuro (lo usan las barras superiores). */
val LocalIsDarkTheme = staticCompositionLocalOf { false }

fun colorSchemeFor(theme: AppThemeOption, dark: Boolean): ColorScheme = when (theme) {
    AppThemeOption.GUINDA -> if (dark) GuindaDark else GuindaLight
    AppThemeOption.AZUL -> if (dark) AzulDark else AzulLight
}

/**
 * Tema de la app: combina el color institucional elegido con el modo claro/oscuro.
 * En modo "Sistema" se adapta automáticamente al modo del dispositivo.
 */
@Composable
fun CamaraMicrofonoTheme(
    theme: AppThemeOption,
    appearance: AppearanceMode,
    content: @Composable () -> Unit,
) {
    val dark = when (appearance) {
        AppearanceMode.SISTEMA -> isSystemInDarkTheme()
        AppearanceMode.CLARO -> false
        AppearanceMode.OSCURO -> true
    }
    CompositionLocalProvider(LocalIsDarkTheme provides dark) {
        MaterialTheme(colorScheme = colorSchemeFor(theme, dark), content = content)
    }
}

/**
 * Barra superior con el color institucional en modo claro (como la app Flutter del
 * Ejercicio 4) y con fondo de superficie + título del color primario en modo oscuro.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun appTopBarColors(): TopAppBarColors {
    val scheme = MaterialTheme.colorScheme
    return if (LocalIsDarkTheme.current) {
        TopAppBarDefaults.topAppBarColors(
            containerColor = scheme.surface,
            titleContentColor = scheme.primary,
            navigationIconContentColor = scheme.primary,
            actionIconContentColor = scheme.primary,
        )
    } else {
        TopAppBarDefaults.topAppBarColors(
            containerColor = scheme.primary,
            titleContentColor = scheme.onPrimary,
            navigationIconContentColor = scheme.onPrimary,
            actionIconContentColor = scheme.onPrimary,
        )
    }
}

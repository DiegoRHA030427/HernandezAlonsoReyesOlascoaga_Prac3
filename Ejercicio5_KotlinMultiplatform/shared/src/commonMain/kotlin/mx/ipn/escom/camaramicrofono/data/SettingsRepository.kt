package mx.ipn.escom.camaramicrofono.data

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import mx.ipn.escom.camaramicrofono.db.CamaraMicrofonoDatabase
import mx.ipn.escom.camaramicrofono.domain.AppSettings
import mx.ipn.escom.camaramicrofono.domain.AppThemeOption
import mx.ipn.escom.camaramicrofono.domain.AppearanceMode
import mx.ipn.escom.camaramicrofono.util.normalizeAlbum

/**
 * Preferencias persistentes en la tabla `AppSetting` de SQLDelight
 * (equivalente a `SettingsStore` con UserDefaults del Ejercicio 3).
 */
class SettingsRepository(database: CamaraMicrofonoDatabase) {
    private val queries = database.appSettingQueries

    val settings: Flow<AppSettings> = queries.selectAll()
        .asFlow()
        .mapToList(Dispatchers.Default)
        .map { rows ->
            val values = rows.associate { it.settingKey to it.settingValue }
            AppSettings(
                theme = AppThemeOption.fromName(values[KEY_THEME]),
                appearance = AppearanceMode.fromName(values[KEY_APPEARANCE]),
                defaultAlbum = values[KEY_DEFAULT_ALBUM] ?: AppSettings.DEFAULT_ALBUM,
            )
        }

    fun setTheme(theme: AppThemeOption) {
        queries.upsert(KEY_THEME, theme.name)
    }

    fun setAppearance(mode: AppearanceMode) {
        queries.upsert(KEY_APPEARANCE, mode.name)
    }

    fun setDefaultAlbum(album: String) {
        queries.upsert(KEY_DEFAULT_ALBUM, normalizeAlbum(album))
    }

    private companion object {
        const val KEY_THEME = "cm.appTheme"
        const val KEY_APPEARANCE = "cm.appearance"
        const val KEY_DEFAULT_ALBUM = "cm.defaultAlbum"
    }
}

package mx.ipn.escom.camaramicrofono.domain

/** Temas institucionales (mismos que `AppTheme` de los Ejercicios 2, 3 y 4). */
enum class AppThemeOption(val displayName: String) {
    GUINDA("Guinda (IPN)"),
    AZUL("Azul (ESCOM)");

    companion object {
        fun fromName(name: String?): AppThemeOption = entries.firstOrNull { it.name == name } ?: GUINDA
    }
}

/** Modo de apariencia. Por defecto se sigue el modo claro/oscuro del sistema. */
enum class AppearanceMode(val label: String) {
    SISTEMA("Sistema"),
    CLARO("Claro"),
    OSCURO("Oscuro");

    companion object {
        fun fromName(name: String?): AppearanceMode = entries.firstOrNull { it.name == name } ?: SISTEMA
    }
}

/** Preferencias persistentes (equivalente a `SettingsStore` del Ejercicio 3). */
data class AppSettings(
    val theme: AppThemeOption = AppThemeOption.GUINDA,
    val appearance: AppearanceMode = AppearanceMode.SISTEMA,
    val defaultAlbum: String = DEFAULT_ALBUM,
) {
    companion object {
        const val DEFAULT_ALBUM = "General"
    }
}

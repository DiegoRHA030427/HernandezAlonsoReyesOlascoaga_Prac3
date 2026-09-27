package mx.ipn.escom.camaramicrofono.di

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import mx.ipn.escom.camaramicrofono.data.MediaRepository
import mx.ipn.escom.camaramicrofono.data.SettingsRepository
import mx.ipn.escom.camaramicrofono.db.CamaraMicrofonoDatabase
import mx.ipn.escom.camaramicrofono.platform.DatabaseDriverFactory

/**
 * Inyección de dependencias manual: una sola base de datos para toda la app
 * (equivalente a `PersistenceController.shared` del Ejercicio 3).
 */
object AppContainer {
    private val database: CamaraMicrofonoDatabase by lazy {
        CamaraMicrofonoDatabase(DatabaseDriverFactory().createDriver())
    }

    val media: MediaRepository by lazy { MediaRepository(database) }

    val settings: SettingsRepository by lazy { SettingsRepository(database) }

    /**
     * Ámbito de corrutinas de toda la app. Los guardados se lanzan aquí y no en el
     * ámbito de la pantalla, para que no se cancelen si el usuario cambia de pestaña
     * mientras se obtiene la ubicación o se escribe el archivo.
     */
    val appScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
}

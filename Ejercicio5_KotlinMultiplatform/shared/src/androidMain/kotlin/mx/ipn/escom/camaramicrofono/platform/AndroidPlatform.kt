package mx.ipn.escom.camaramicrofono.platform

import android.content.Context

/**
 * Guarda el Context de la aplicación para las implementaciones "actual" de Android
 * (archivos, base de datos, ubicación, compartir). Se inicializa en
 * `CamaraMicrofonoApp.onCreate()` del módulo androidApp.
 */
object AndroidPlatform {
    lateinit var context: Context
        private set

    fun init(context: Context) {
        this.context = context.applicationContext
    }
}

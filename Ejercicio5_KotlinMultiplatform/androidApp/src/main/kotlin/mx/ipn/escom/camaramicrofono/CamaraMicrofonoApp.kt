package mx.ipn.escom.camaramicrofono

import android.app.Application
import mx.ipn.escom.camaramicrofono.platform.AndroidPlatform

class CamaraMicrofonoApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // Las implementaciones "actual" de Android necesitan el Context de la app
        // (archivos, base de datos, ubicación, compartir).
        AndroidPlatform.init(this)
    }
}

package mx.ipn.escom.camaramicrofono.platform

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import mx.ipn.escom.camaramicrofono.db.CamaraMicrofonoDatabase

actual class DatabaseDriverFactory actual constructor() {
    actual fun createDriver(): SqlDriver =
        AndroidSqliteDriver(CamaraMicrofonoDatabase.Schema, AndroidPlatform.context, "camara_microfono.db")
}

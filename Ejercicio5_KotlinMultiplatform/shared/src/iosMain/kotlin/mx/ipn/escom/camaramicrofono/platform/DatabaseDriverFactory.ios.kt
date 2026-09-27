package mx.ipn.escom.camaramicrofono.platform

import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import mx.ipn.escom.camaramicrofono.db.CamaraMicrofonoDatabase

actual class DatabaseDriverFactory actual constructor() {
    actual fun createDriver(): SqlDriver =
        NativeSqliteDriver(CamaraMicrofonoDatabase.Schema, "camara_microfono.db")
}

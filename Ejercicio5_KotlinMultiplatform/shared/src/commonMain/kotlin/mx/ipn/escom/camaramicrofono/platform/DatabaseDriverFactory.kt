package mx.ipn.escom.camaramicrofono.platform

import app.cash.sqldelight.db.SqlDriver

/**
 * Crea el driver de SQLite de cada plataforma para SQLDelight:
 * - Android: `AndroidSqliteDriver` (necesita el Context de la app).
 * - iOS: `NativeSqliteDriver`.
 */
expect class DatabaseDriverFactory() {
    fun createDriver(): SqlDriver
}

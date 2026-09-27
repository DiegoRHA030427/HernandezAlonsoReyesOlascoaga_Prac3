package mx.ipn.escom.camaramicrofono.platform

// ---------------------------------------------------------------------------
// Utilidades del sistema que cambian entre plataformas (expect/actual).
// ---------------------------------------------------------------------------

/** Nombre y versión del sistema operativo, para la pantalla "Acerca de". */
expect val platformName: String

/** Hora actual en milisegundos desde 1970 (epoch). */
expect fun currentTimeMillis(): Long

/** Fecha legible en español, p. ej. "27 sep 2026, 14:05". */
expect fun formatDateTime(epochMillis: Long): String

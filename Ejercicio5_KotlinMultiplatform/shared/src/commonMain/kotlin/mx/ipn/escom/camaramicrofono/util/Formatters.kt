package mx.ipn.escom.camaramicrofono.util

import kotlin.math.abs
import kotlin.math.roundToLong

/** "mm:ss" (igual que `formatted(_:)` en AudioRecorderView del Ejercicio 3). */
fun formatDuration(seconds: Double): String {
    val total = seconds.coerceAtLeast(0.0).toInt()
    val minutes = total / 60
    val secs = total % 60
    return "${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}"
}

/** Coordenadas con 5 decimales, p. ej. "19.50460° N, 99.14690° O". */
fun formatCoordinates(latitude: Double, longitude: Double): String {
    val lat = "${decimals(abs(latitude), 5)}° ${if (latitude >= 0) "N" else "S"}"
    val lon = "${decimals(abs(longitude), 5)}° ${if (longitude >= 0) "E" else "O"}"
    return "$lat, $lon"
}

/** Redondeo a [places] decimales sin depender de String.format (no existe en común). */
fun decimals(value: Double, places: Int): String {
    var factor = 1L
    repeat(places) { factor *= 10 }
    val scaled = (value * factor).roundToLong()
    val integer = scaled / factor
    val fraction = (scaled % factor).toString().padStart(places, '0')
    return if (places == 0) integer.toString() else "$integer.$fraction"
}

/** Normaliza el nombre de un álbum: sin espacios sobrantes y "General" si queda vacío. */
fun normalizeAlbum(name: String, fallback: String = "General"): String =
    name.trim().ifEmpty { fallback }

/** Lista de álbumes para el filtro de la galería: "Todos", "General" y el resto ordenados. */
fun albumFilterOptions(albums: Collection<String>, allLabel: String = "Todos"): List<String> =
    listOf(allLabel) + (albums + "General").map { it.trim() }.filter { it.isNotEmpty() }.distinct().sorted()

package mx.ipn.escom.camaramicrofono.domain

/**
 * Filtros básicos de captura (mismos que `PhotoFilter` del Ejercicio 3).
 * La forma de aplicarlos cambia en cada plataforma (ColorMatrix en Android,
 * Core Image en iOS), por eso el procesamiento está en `ImageProcessor` (expect/actual).
 */
enum class PhotoFilter(val label: String) {
    NINGUNO("Ninguno"),
    SEPIA("Sepia"),
    BLANCO_Y_NEGRO("Blanco y negro"),
    VIVIDO("Vívido"),
}

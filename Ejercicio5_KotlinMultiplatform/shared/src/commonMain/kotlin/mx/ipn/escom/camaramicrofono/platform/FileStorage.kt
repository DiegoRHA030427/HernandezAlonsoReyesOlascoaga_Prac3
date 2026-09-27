package mx.ipn.escom.camaramicrofono.platform

/**
 * Acceso al sistema de archivos del sandbox de la app (expect/actual).
 * Las fotos y audios viven en la carpeta "Capturas", igual que en el Ejercicio 3:
 * - Android: /data/data/<paquete>/files/Capturas  y temporales en .../cache
 * - iOS:     <App>/Documents/Capturas              y temporales en <App>/tmp
 */
expect object FileStorage {
    /** Ruta absoluta de un archivo dentro de la carpeta "Capturas". */
    fun mediaPath(fileName: String): String

    /** Ruta absoluta de un archivo temporal (se usa mientras se graba el audio). */
    fun tempPath(fileName: String): String

    fun writeBytes(path: String, bytes: ByteArray): Boolean

    fun readBytes(path: String): ByteArray?

    fun exists(path: String): Boolean

    fun delete(path: String): Boolean

    /** Mueve (o copia y borra) un archivo; sobrescribe el destino si existe. */
    fun move(fromPath: String, toPath: String): Boolean
}

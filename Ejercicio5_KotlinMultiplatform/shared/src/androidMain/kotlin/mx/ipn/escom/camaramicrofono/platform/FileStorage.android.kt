package mx.ipn.escom.camaramicrofono.platform

import java.io.File

/** Archivos en el almacenamiento interno de la app (no requiere permisos de almacenamiento). */
actual object FileStorage {
    private val mediaDir: File
        get() = File(AndroidPlatform.context.filesDir, "Capturas").apply { mkdirs() }

    actual fun mediaPath(fileName: String): String = File(mediaDir, fileName).absolutePath

    actual fun tempPath(fileName: String): String = File(AndroidPlatform.context.cacheDir, fileName).absolutePath

    actual fun writeBytes(path: String, bytes: ByteArray): Boolean = runCatching {
        File(path).apply { parentFile?.mkdirs() }.writeBytes(bytes)
    }.isSuccess

    actual fun readBytes(path: String): ByteArray? = runCatching { File(path).readBytes() }.getOrNull()

    actual fun exists(path: String): Boolean = File(path).exists()

    actual fun delete(path: String): Boolean = File(path).delete()

    actual fun move(fromPath: String, toPath: String): Boolean {
        val source = File(fromPath)
        val target = File(toPath).apply { parentFile?.mkdirs() }
        if (target.exists()) target.delete()
        if (source.renameTo(target)) return true
        // renameTo falla entre volúmenes distintos (cache -> files en algunos equipos).
        return runCatching {
            source.copyTo(target, overwrite = true)
            source.delete()
            true
        }.getOrDefault(false)
    }
}

package mx.ipn.escom.camaramicrofono.platform

import kotlinx.cinterop.ExperimentalForeignApi
import platform.Foundation.*

/** Archivos dentro del sandbox de la app con NSFileManager (igual que MediaStore del Ejercicio 3). */
@OptIn(ExperimentalForeignApi::class)
actual object FileStorage {
    private val fileManager = NSFileManager.defaultManager

    private val mediaDir: String
        get() {
            val documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).first() as String
            val dir = "$documents/Capturas"
            if (!fileManager.fileExistsAtPath(dir)) {
                fileManager.createDirectoryAtPath(dir, withIntermediateDirectories = true, attributes = null, error = null)
            }
            return dir
        }

    actual fun mediaPath(fileName: String): String = "$mediaDir/$fileName"

    actual fun tempPath(fileName: String): String = NSTemporaryDirectory().trimEnd('/') + "/" + fileName

    actual fun writeBytes(path: String, bytes: ByteArray): Boolean = bytes.toNSData().writeToFile(path, atomically = true)

    actual fun readBytes(path: String): ByteArray? = NSData.dataWithContentsOfFile(path)?.toByteArray()

    actual fun exists(path: String): Boolean = fileManager.fileExistsAtPath(path)

    actual fun delete(path: String): Boolean = fileManager.removeItemAtPath(path, error = null)

    actual fun move(fromPath: String, toPath: String): Boolean {
        if (fileManager.fileExistsAtPath(toPath)) fileManager.removeItemAtPath(toPath, error = null)
        return fileManager.moveItemAtPath(fromPath, toPath = toPath, error = null)
    }
}

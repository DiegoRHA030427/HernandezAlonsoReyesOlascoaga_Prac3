package mx.ipn.escom.camaramicrofono.platform

import platform.Foundation.*
import platform.UIKit.*

actual val platformName: String =
    UIDevice.currentDevice.systemName + " " + UIDevice.currentDevice.systemVersion

actual fun currentTimeMillis(): Long = (NSDate().timeIntervalSince1970 * 1000).toLong()

actual fun formatDateTime(epochMillis: Long): String {
    val formatter = NSDateFormatter().apply {
        dateFormat = "d MMM yyyy, HH:mm"
        locale = NSLocale(localeIdentifier = "es_MX")
    }
    return formatter.stringFromDate(NSDate.dateWithTimeIntervalSince1970(epochMillis / 1000.0))
}

package mx.ipn.escom.camaramicrofono.platform

import android.os.Build
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

actual val platformName: String = "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

actual fun currentTimeMillis(): Long = System.currentTimeMillis()

actual fun formatDateTime(epochMillis: Long): String =
    SimpleDateFormat("d MMM yyyy, HH:mm", Locale.forLanguageTag("es-MX")).format(Date(epochMillis))

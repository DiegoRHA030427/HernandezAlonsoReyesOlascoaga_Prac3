# Comparación entre Flutter y Kotlin Multiplatform

Sección 5.5 del informe. Compara las dos apps multiplataforma de la práctica: el **Gestor de Archivos en Flutter** (Ejercicio 4) y la app de **Cámara y Micrófono en Kotlin Multiplatform** (Ejercicio 5). Los datos de código, tamaño y compilación salen de nuestros propios proyectos. Se midieron en la PC de Diego (Windows 11, Android Studio, emulador Medium Phone con Android 17 / API 37).

## Tabla comparativa

| Criterio | Flutter (Ejercicio 4) | Kotlin Multiplatform (Ejercicio 5) |
|---|---|---|
| **Lenguaje** | Dart 3 (tipado estático, *null safety*, `async`/`await`). Es un lenguaje que hubo que aprender solo para Flutter. | Kotlin 2.4 (tipado estático, *null safety*, corrutinas y `Flow`). Es el lenguaje oficial de Android, así que se reutiliza lo que ya se sabe de Android. |
| **Qué se comparte** | Todo: lógica, estado e interfaz se escriben una sola vez en Dart. | La lógica de negocio siempre. La interfaz también, si se usa Compose Multiplatform (como en esta práctica). También se puede hacer la UI nativa (SwiftUI) y compartir solo la lógica. |
| **Construcción de la interfaz** | Árbol de *widgets* declarativo (`MaterialApp`, `Scaffold`, `ListView`…). Flutter dibuja cada píxel con su propio motor (Impeller), así que se ve igual en Android y en iOS. | Funciones `@Composable` declarativas (Compose Multiplatform). En Android es Jetpack Compose, el toolkit nativo. En iOS Compose dibuja con Skia dentro de un `UIViewController`. |
| **Estructura del proyecto** | Un solo proyecto con arquitectura limpia: `domain/`, `data/`, `presentation/`. Las carpetas `android/` e `ios/` solo son "cascarones" generados. | Módulo `shared` con `commonMain` (lógica + UI), `androidMain` e `iosMain` (código nativo), más `androidApp` e `iosApp` (puntos de entrada). |
| **Acceso a APIs nativas** | Mediante *plugins* de pub.dev que se comunican con el sistema por *platform channels*: `path_provider`, `file_picker`, `share_plus`, `open_filex`. No escribimos código nativo. | Con `expect`/`actual`: se declara la interfaz en `commonMain` y se implementa en cada plataforma llamando directo al SDK (CameraX, `AudioRecord`, `MediaPlayer` en Android; `AVAudioRecorder`, `UIImagePickerController`, `CLLocationManager` en iOS). No hay puente intermedio. |
| **Gestión de estado** | `Provider` (`ChangeNotifier`), con un provider por responsabilidad: explorador, ajustes, favoritos, recientes. | Estado de Compose (`remember`, `mutableStateOf`) + `Flow` de SQLDelight: la galería se actualiza sola cuando cambia la tabla. |
| **Asincronía** | `Future`/`async`/`await` de Dart. | Corrutinas (`launch`, `withContext(Dispatchers.Default)`) y `Flow`; un ámbito de toda la app (`appScope`) para que los guardados no se cancelen. |
| **Persistencia local** | Hive (clave-valor, en Dart puro, sin generar código): tema, orden, favoritos y recientes. | SQLDelight (SQLite con consultas `.sq` verificadas al compilar): tablas `CapturedItem` y `AppSetting`. El driver cambia por plataforma con `expect`/`actual`. |
| **Código compartido (medido)** | 33 archivos Dart, 2,582 líneas → **100 %** compartido. Todo lo nativo lo aportan los plugins. | 3,445 líneas en `shared/src` (sin contar pruebas): `commonMain` 2,351 (**≈ 68 %**), `androidMain` 582 (≈ 17 %), `iosMain` 512 (≈ 15 %). |
| **Tamaño del binario (APK release)** | **53.2 MB**. Incluye el motor de Flutter (`libflutter.so`) y el código compilado (`libapp.so`) para 3 arquitecturas de CPU (arm64, armv7, x86_64). Con `flutter build apk --split-per-abi` se genera un APK más pequeño por arquitectura. | **15.1 MB**, sin minificación con R8. No incluye un motor propio porque Compose es parte de la app Android y casi todo el peso es *bytecode* (DEX). Con R8 activado se reduciría todavía más. |
| **Compilación** | Primera compilación lenta (descarga del motor y plugins). *Hot reload* en menos de 1 s mientras la app está corriendo. | Primera compilación 3 min 37 s (descarga de dependencias). Las reinstalaciones siguientes tardaron entre 5 y 40 s. No hay *hot reload* para el emulador de Android; se reinstala la app. |
| **Temas Guinda / Azul** | `ThemeData` + `ColorScheme.fromSeed` con `#9B023D` y `#003E80`; modo Sistema/Claro/Oscuro con `ThemeMode`. | `MaterialTheme` de Compose con los mismos colores y los mismos tres modos; la elección se guarda en SQLDelight. |
| **Permisos** | Los piden los plugins. En esta app casi no hacen falta, porque solo se usa el sandbox de la app. | `rememberPermissionState` con `expect`/`actual`: Activity Result API + `AndroidManifest.xml` en Android; `AVCaptureDevice` / `AVAudioSession` / `CLLocationManager` + `Info.plist` en iOS. |
| **Pruebas** | 11 pruebas (unitarias y de widgets) con `flutter test`; `flutter analyze` sin advertencias. | 8 pruebas de `commonTest` (8/8 aprobadas con `gradlew :shared:testAndroidHostTest`) que validan la lógica compartida una sola vez para ambas plataformas. |
| **Compilación para iOS** | Requiere Mac con Xcode 15 o superior. | Requiere Mac con **Apple Silicon** y Xcode 16 o superior. El proyecto solo declara los targets `iosArm64` e `iosSimulatorArm64`. |
| **Curva de aprendizaje** | Media: hay que aprender Dart y el modelo de *widgets*, pero la documentación y los ejemplos son abundantes y el *hot reload* ayuda mucho. | Media-alta: es sencillo si ya se sabe Kotlin/Android, pero hay que entender Gradle multiplataforma, `expect`/`actual` y la interoperabilidad con Objective-C/Swift para iOS. |
| **Madurez del ecosistema** | Alta: estable desde 2018, con miles de paquetes en pub.dev para casi cualquier recurso del dispositivo. | En crecimiento: KMP es estable desde noviembre de 2023 y Compose Multiplatform para iOS desde mayo de 2025 (versión 1.8.0). Hay menos bibliotecas multiplataforma, pero se puede usar cualquier biblioteca nativa. |
| **Problemas que tuvimos** | Plugins antiguos (`file_picker 8`, `share_plus 10`) no compilaban con Gradle 9 / AGP 9 y hubo que actualizarlos a versiones con otra API. | Un guardado se cancelaba al cambiar de pestaña (se resolvió con un ámbito de corrutinas de toda la app). El micrófono virtual del emulador alteraba la duración de los audios. |
| **Funcionamiento sin conexión** | 100 %: todo se guarda en el dispositivo. | 100 %: la app ni siquiera declara el permiso `INTERNET`. |

## Puntos clave

1. **Cuánto se comparte.** Flutter comparte el 100 % del código escrito por el equipo, porque los plugins esconden lo nativo. En KMP se compartió ≈ 68 % y el resto es código nativo escrito por nosotros con `expect`/`actual`.
2. **Acceso al hardware.** En la app de cámara y micrófono, KMP dio control directo sobre CameraX y `AudioRecord`. Eso permitió aplicar ganancia por software y corregir la duración del audio en el emulador. En Flutter ese nivel de control depende de lo que exponga el plugin.
3. **Productividad.** Flutter fue más rápido de iterar gracias al *hot reload*. En KMP cada cambio implicó recompilar y reinstalar, aunque las recompilaciones incrementales fueron cortas.
4. **Ecosistema.** Flutter tiene más paquetes listos. KMP tiene menos bibliotecas multiplataforma, pero puede usar cualquier biblioteca de Android o de iOS directamente.
5. **Tamaño.** El APK release de KMP (15.1 MB) pesa menos de un tercio que el de Flutter (53.2 MB), porque Flutter empaqueta su propio motor de renderizado para cada arquitectura de CPU.
6. **iOS.** Ambos necesitan una Mac para generar la app de iOS, pero KMP con Compose Multiplatform exige hardware más reciente (Apple Silicon + Xcode 16). La VM de Julio (Intel, Xcode 14.3.1) no puede compilar esa parte.

## Conclusión

Las dos tecnologías cumplieron los requisitos de la práctica: temas Guinda/Azul con modo claro y oscuro, persistencia local y funcionamiento sin internet.

**Flutter** conviene cuando se busca desarrollar rápido con un solo código y una interfaz idéntica en ambas plataformas, y cuando los plugins existentes cubren los recursos del dispositivo que se necesitan. Fue el caso del Gestor de Archivos.

**Kotlin Multiplatform** conviene cuando se necesita control fino de las APIs nativas, o cuando el equipo ya trabaja en Kotlin/Android. Permite compartir la lógica sin renunciar a lo nativo, como en la app de Cámara y Micrófono. A cambio pide más configuración (Gradle, `expect`/`actual`, requisitos de Xcode) y su ecosistema todavía es más joven.

Para este equipo, sin Mac física y con experiencia previa en Android, Flutter resultó más productivo. KMP resultó más flexible para trabajar con el hardware.

## Formato sugerido para el PDF

- Insertar la tabla como **Tabla 5.1 — Comparación entre Flutter y Kotlin Multiplatform**, con 3 columnas: *Criterio* (≈ 20 % del ancho), *Flutter* y *Kotlin Multiplatform* (≈ 40 % cada una).
- Encabezado con fondo guinda `#9B023D` y texto blanco en negritas; filas alternadas en gris muy claro; letra de 9–10 pt; la columna *Criterio* en negritas.
- Si la tabla no cabe en vertical, usar una página horizontal solo para ella, o dividirla en dos partes (técnica: lenguaje → pruebas; práctica: iOS → sin conexión).
- Poner los *Puntos clave* como lista debajo de la tabla y la *Conclusión* como párrafo al final de la sección 5.5. La conclusión también sirve como base para la parte de Flutter/KMP en las Conclusiones generales del informe.

### Fuentes
- JetBrains (2025). *Compose Multiplatform 1.8.0 Released: Compose Multiplatform for iOS Is Stable and Production-Ready*. https://blog.jetbrains.com/kotlin/2025/05/compose-multiplatform-1-8-0-released-compose-multiplatform-for-ios-is-stable-and-production-ready/
- Google (s.f.). *Flutter documentation*. https://docs.flutter.dev
- JetBrains (s.f.). *Kotlin Multiplatform documentation*. https://kotlinlang.org/docs/multiplatform.html
- Cash App (s.f.). *SQLDelight documentation*. https://sqldelight.github.io/sqldelight/

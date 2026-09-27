# Práctica 3: Aplicaciones Nativas

Proyecto en equipo para la materia de **Desarrollo de Aplicaciones Móviles Nativas** — IPN, ESCOM.

La práctica consta de 5 ejercicios. Este repositorio reúne el trabajo de ambos integrantes del equipo:

| Ejercicio | Descripción | Plataforma | Responsable |
|---|---|---|---|
| 1 | Instalación y configuración del entorno de desarrollo nativo (iOS) | macOS / Xcode | Julio Olascoaga |
| 2 | Gestor de archivos nativo | iOS (Swift/SwiftUI) | Julio Olascoaga |
| 3 | Aplicación de cámara y micrófono | iOS (Swift/SwiftUI) | Julio Olascoaga |
| 4 | Aplicación multiplataforma | Flutter | *(en progreso — completar)* |
| 5 | Aplicación multiplataforma | Kotlin Multiplatform | *(en progreso — completar)* |

> Los nombres del equipo en la tabla son un punto de partida — ajusta o completa según corresponda.

## Estructura del repositorio

```
.
├── README.md
├── Ejercicio1_Entorno/              # Notas de instalación del entorno (ver abajo)
├── Ejercicio2_GestorArchivos/       # Proyecto Xcode — Gestor de Archivos
├── Ejercicio3_CamaraMicrofono/      # Proyecto Xcode — Cámara y Micrófono
├── Ejercicio4_Flutter/              # Proyecto Flutter
└── Ejercicio5_KotlinMultiplatform/  # Proyecto Kotlin Multiplatform
```

---

## Ejercicio 1 — Entorno de desarrollo

El desarrollo nativo de iOS (Ejercicios 2 y 3) se hizo **sin una Mac física**, usando una máquina virtual de macOS anidada:

- **Host:** Windows + WSL2
- **VM:** macOS Ventura vía [docker-osx](https://github.com/sickcodes/docker-osx) (QEMU/KVM)
- **IDE:** Xcode 14.3.1
- **Simulador:** iPhone 14, iOS 16.4

Esta configuración es funcional pero tiene limitaciones de hardware/servicios frente a una Mac real, que se documentan en el Ejercicio 3 porque ahí es donde se notan (cámara, micrófono, GPU).

### Evidencia

| Especificaciones de la PC usada | Instalación de WSL2 |
|---|---|
| ![Specs de la PC](capturas/ejercicio1/01-specs-pc.png) | ![Instalación de WSL2](capturas/ejercicio1/02-wsl-install.png) |

| macOS Ventura en QEMU (docker-osx) | Proyecto de prueba SwiftUI en el simulador |
|---|---|
| ![macOS en QEMU](capturas/ejercicio1/03-macos-vm-appleid.png) | ![Hello world en simulador](capturas/ejercicio1/04-helloworld-simulador.png) |

---

## Ejercicio 2 — Gestor de Archivos

**Carpeta:** `Ejercicio2_GestorArchivos/` · Swift 5 + SwiftUI

Gestor de archivos con sandbox propio de la app (`Documents/Inbox`), con las siguientes funciones:

- Explorador de carpetas con navegación (`NavigationStack`), creación de carpetas, búsqueda y ordenamiento (nombre, fecha, tamaño).
- Importar archivos desde el sistema (`UIDocumentPickerViewController`) y exportar/compartir (`UIActivityViewController`).
- Visor de archivos: imágenes con zoom, y vista previa de otros tipos con `QLPreviewController`.
- Iconos por tipo de archivo (`UTType`) y miniaturas cacheadas (`NSCache`) para que la galería cargue rápido.
- Gestos: swipe para acciones rápidas, menú contextual (mantener presionado), pull-to-refresh.
- Favoritos y persistencia de preferencias con `UserDefaults`; acceso a carpetas externas con *security-scoped bookmarks*.
- Temas institucionales **Guinda (IPN)** y **Azul (ESCOM)**, adaptados a modo claro/oscuro.

**Archivos principales:** `FileBrowserView`, `FileBrowserViewModel`, `FileSystemService`, `FileSystemModels`, `FileViewers`, `FileRowView`, `DestinationPickerView`, `PersistenceStores`, `SystemWrappers`, `AppTheme`, `RootTabView`, `GestorArchivosApp`.

### Evidencia

| Proyecto en Xcode | Build settings (iOS 16.4) |
|---|---|
| ![Proyecto en Xcode](capturas/ejercicio2/01-xcode-proyecto.png) | ![Build settings](capturas/ejercicio2/02-build-settings.png) |

| Pantalla principal (Documents / Inbox / Temporal) | Favoritos |
|---|---|
| ![Gestor de Archivos - inicio](capturas/ejercicio2/03-gestor-home.png) | ![Favoritos](capturas/ejercicio2/04-favoritos.png) |

### Cómo ejecutarlo
1. Abrir `Ejercicio2_GestorArchivos/` en Xcode (14.0+).
2. Seleccionar un simulador de iPhone.
3. `Cmd/⊞ + R` para compilar y correr.

---

## Ejercicio 3 — Cámara y Micrófono

**Carpeta:** `Ejercicio3_CamaraMicrofono/` · Swift 5 + SwiftUI + AVFoundation + Core Data

App con cuatro pestañas: **Cámara**, **Audio**, **Galería**, **Ajustes**.

### Cámara
- Captura con `AVCaptureSession` / `AVCapturePhotoOutput`, flash y temporizador (3/5/10 s).
- Filtros con Core Image (`CIFilter`): Sepia, Blanco y negro, Vívido.
- El simulador de iOS no tiene cámara física: como alternativa documentada, se puede elegir una foto de la fototeca (`PHPickerViewController`).

### Audio
- Grabación con `AVAudioRecorder`: medidor de nivel, "sensibilidad" (ganancia de entrada, cuando el hardware lo permite) y temporizador de grabación (15/30/60 s o sin límite).
- Reproducción con `AVAudioPlayer` (progreso, favoritos).
- Alternativa para importar un archivo de audio existente cuando no hay micrófono disponible en el entorno.

### Galería y edición
- Galería con `@FetchRequest` de Core Data, filtrable por álbum.
- Edición básica: rotar, reaplicar filtro, favoritos, etiquetas/álbum, compartir, eliminar.

### Core Data
Entidad `CapturedItem` (modelo `CamaraMicrofono.xcdatamodeld`): `id`, `type`, `fileName`, `dateCreated`, `albumName`, `tags`, `isFavorite`, `latitude`, `longitude`, `hasLocation`, `duration`. La ubicación se obtiene de forma opcional y no bloqueante (`CLLocationManager`, con *timeout* de 3 s).

**Archivos principales:** `CameraCaptureView`, `AudioRecorderView`, `AudioPlayerView`, `GalleryView`, `PhotoDetailView`, `MediaStore`, `PersistenceController`, `LocationHelper`, `AppTheme`, `RootTabView`, `CamaraMicrofonoApp`.

### Cómo ejecutarlo
1. Abrir `Ejercicio3_CamaraMicrofono/` en Xcode.
2. Seleccionar destino **iPhone 14** (o cualquier simulador de iPhone) — **no** "My Mac".
3. `Cmd/⊞ + R`.
4. Al primer uso, aceptar los permisos de cámara/micrófono/ubicación que pide el sistema.

### Limitaciones conocidas del entorno (VM anidada)
Al no correr en una Mac física, el simulador dentro de la VM carece de ciertos servicios que una Mac real sí tiene. Se documentan aquí porque son del entorno, no bugs de la app:

| Limitación | Síntoma | Solución aplicada |
|---|---|---|
| Sin cámara física | N/A en cualquier simulador de iOS | Selector de fototeca como alternativa (permitido por el enunciado) |
| Sin micrófono real en la VM | La grabación no captura audio | Si no hay hardware disponible, se genera un audio de respaldo (silencioso) con la duración grabada, para que guardar/reproducir sigan siendo funcionales de extremo a extremo; también existe la opción de importar un archivo de audio existente |
| Sin aceleración GPU/Metal | Los filtros de Core Image no se aplicaban | Se forzó el renderizado por software (`CIContext(options: [.useSoftwareRenderer: true])`) |
| Servicio de conversión de Fotos inestable | Alguna foto en particular podía fallar al elegirla de la fototeca | Manejo de error explícito: si una foto falla, se avisa en pantalla para intentar con otra, en vez de que la app se cierre |

### Evidencia

| Selección desde la fototeca (cámara) | Grabación de audio en curso |
|---|---|
| ![Fototeca](capturas/ejercicio3/01-camara-fototeca.png) | ![Grabando audio](capturas/ejercicio3/02-audio-grabando.png) |

| Guardar grabación (16 s) | Reproducción (duración 00:16) |
|---|---|
| ![Guardar audio](capturas/ejercicio3/03-audio-guardar.png) | ![Reproducción de audio](capturas/ejercicio3/04-audio-reproduccion.png) |

Durante el desarrollo también se depuraron errores de compilación reales, documentados como evidencia del proceso:

| Error de Core Data (modelo faltante) | Error de destino "My Mac" en vez de simulador |
|---|---|
| ![Error Core Data](capturas/ejercicio3/05-debug-coredata.png) | ![Error destino My Mac](capturas/ejercicio3/06-debug-destino.png) |

---

## Ejercicio 4 — Flutter
*(pendiente — completar por el equipo)*

## Ejercicio 5 — Kotlin Multiplatform
*(pendiente — completar por el equipo)*

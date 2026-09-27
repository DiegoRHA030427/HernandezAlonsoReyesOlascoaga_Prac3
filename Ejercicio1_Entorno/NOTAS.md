# Ejercicio 1 — Entorno de desarrollo

Configuración usada para el desarrollo nativo de iOS (Ejercicios 2 y 3), sin contar con una Mac física:

- **Host:** Windows + WSL2
- **Máquina virtual:** macOS Ventura, corrida con [docker-osx](https://github.com/sickcodes/docker-osx) sobre QEMU/KVM
- **IDE:** Xcode 14.3.1
- **SDK / Simulador:** iOS 16.4, iPhone 14

### Pasos generales seguidos
1. Instalación de Docker Desktop + WSL2 en Windows.
2. Descarga y arranque de la imagen `docker-osx` con macOS Ventura.
3. Instalación de Xcode 14.3.1 dentro de la VM desde el App Store / Apple Developer.
4. Instalación de Google Chrome dentro de la VM para poder descargar archivos (transferencia de código entre el entorno de trabajo y la VM).
5. Configuración de un simulador de iPhone 14 con iOS 16.4.

### Notas y limitaciones
Al ser una VM anidada (no una Mac real), el simulador dentro de ella carece de algunos servicios de hardware/sistema (cámara física, micrófono, aceleración GPU/Metal). Estas limitaciones y cómo se resolvieron están documentadas en el README del Ejercicio 3, que es donde se notan.

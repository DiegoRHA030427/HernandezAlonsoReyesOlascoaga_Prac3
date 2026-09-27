/// Contenido de ejemplo que se crea la primera vez que se abre la app,
/// para poder probar los visores sin necesidad de internet ni de importar nada.
const welcomeText = '''
Bienvenido al Gestor de Archivos
Práctica 3 - Ejercicio 4 (Flutter) - IPN · ESCOM

Este archivo se creó automáticamente dentro del sandbox de la app.

Qué puedes hacer:
- Tocar un archivo para abrirlo (texto, imagen o visor del sistema).
- Mantener presionado (o tocar ⋮) para ver todas las acciones:
  favoritos, renombrar, duplicar, copiar, mover, compartir y eliminar.
- Deslizar a la derecha para marcar como favorito.
- Deslizar a la izquierda para eliminar.
- Jalar hacia abajo para actualizar la carpeta.
- Buscar y ordenar por nombre, fecha o tamaño desde la barra superior.
- Cambiar el tema (Guinda IPN / Azul ESCOM) en la pestaña Ajustes.

Todo funciona sin conexión a internet.
''';

const notesMarkdown = '''
# Notas de la práctica

## Arquitectura
- **domain**: entidades, contratos de repositorio y casos de uso (Dart puro).
- **data**: implementación con dart:io, path_provider y Hive.
- **presentation**: pantallas, widgets y providers (gestor de estado).

## Persistencia
Hive guarda el tema, el modo claro/oscuro, el criterio de orden,
la última carpeta visitada, los favoritos y el historial de recientes.
''';

const sampleJson = '''
{
  "practica": 3,
  "ejercicio": 4,
  "tecnologia": "Flutter",
  "gestorEstado": "Provider",
  "persistencia": "Hive",
  "temas": ["Guinda (IPN)", "Azul (ESCOM)"],
  "offline": true
}
''';

const pendingText = '''
Pendientes
[x] Explorador de carpetas del sandbox
[x] Visor de texto e imágenes con zoom
[x] Favoritos y recientes con Hive
[ ] Tomar capturas para el reporte
''';

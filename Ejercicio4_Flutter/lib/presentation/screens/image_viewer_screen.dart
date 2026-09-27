import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/file_item.dart';

/// Visor de imágenes (equivalente a ImageViewerView del Ejercicio 2):
/// zoom con pellizco o con botones, arrastre, rotación de 90° y doble toque
/// para ajustar a la pantalla.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({super.key, required this.item});

  final FileItem item;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  static const _minScale = 1.0;
  static const _maxScale = 8.0;

  final _controller = TransformationController();
  int _quarterTurns = 0;
  Size _viewport = Size.zero;

  void _reset() {
    setState(() {
      _controller.value = Matrix4.identity();
      _quarterTurns = 0;
    });
  }

  void _rotate(int delta) => setState(() => _quarterTurns = (_quarterTurns + delta) % 4);

  /// Zoom con botones, centrado en la pantalla (útil en el emulador, donde el
  /// pellizco de dos dedos no se puede hacer fácilmente con el mouse).
  void _zoom(double factor) {
    final current = _controller.value.getMaxScaleOnAxis();
    final target = (current * factor).clamp(_minScale, _maxScale);
    final f = target / current;
    final cx = _viewport.width / 2;
    final cy = _viewport.height / 2;
    final scaleAroundCenter = Matrix4.translationValues(cx, cy, 0)
        .multiplied(Matrix4.diagonal3Values(f, f, 1))
        .multiplied(Matrix4.translationValues(-cx, -cy, 0));
    setState(() => _controller.value = scaleAroundCenter.multiplied(_controller.value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.item.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Alejar',
            onPressed: () => _zoom(1 / 1.5),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Acercar',
            onPressed: () => _zoom(1.5),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_left),
            tooltip: 'Rotar a la izquierda',
            onPressed: () => _rotate(-1),
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            tooltip: 'Rotar a la derecha',
            onPressed: () => _rotate(1),
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen),
            tooltip: 'Ajustar a pantalla',
            onPressed: _reset,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewport = constraints.biggest;
          return GestureDetector(
            onDoubleTap: _reset,
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: _minScale,
              maxScale: _maxScale,
              child: SizedBox.expand(
                child: RotatedBox(
                  quarterTurns: _quarterTurns,
                  child: Image.file(
                    File(widget.item.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text(
                        'No se pudo cargar la imagen.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/errors/file_operation_exception.dart';
import '../../domain/repositories/file_repository.dart';
import '../utils/dialogs.dart';
import '../widgets/empty_state.dart';

/// Visor/editor de texto (equivalente a TextFileView del Ejercicio 2):
/// abre .txt, .md, .json, .dart, .swift, etc. y permite editar y guardar.
class TextViewerScreen extends StatefulWidget {
  const TextViewerScreen({super.key, required this.item});

  final FileItem item;

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontFamilyFallback: ['Menlo', 'Courier'],
    fontSize: 14,
  );

  final _controller = TextEditingController();
  late final FileRepository _repository;
  bool _loading = true;
  bool _editing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = context.read<FileRepository>();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _controller.text = await _repository.readText(widget.item.path);
    } on FileOperationException catch (e) {
      _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      await _repository.writeText(widget.item.path, _controller.text);
      if (!mounted) return;
      setState(() => _editing = false);
      showSnack(context, 'Cambios guardados');
    } on FileOperationException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !_loading && _error == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name, overflow: TextOverflow.ellipsis),
        actions: [
          if (canEdit)
            IconButton(
              icon: Icon(_editing ? Icons.save_outlined : Icons.edit_outlined),
              tooltip: _editing ? 'Guardar' : 'Editar',
              onPressed: _editing ? _save : () => setState(() => _editing = true),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return EmptyState(message: _error!, icon: Icons.warning_amber_rounded);
    }
    if (_editing) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          autofocus: true,
          textAlignVertical: TextAlignVertical.top,
          style: _mono,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: SelectableText(_controller.text, style: _mono),
      ),
    );
  }
}

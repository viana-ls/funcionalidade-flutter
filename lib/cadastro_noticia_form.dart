import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'noticias_service.dart';

/// Componente de cadastro de notícias: título, resumo, conteúdo e imagem de capa.
/// Ao publicar, grava no Firestore via [NoticiasService] e limpa o formulário.
class CadastroNoticiaForm extends StatefulWidget {
  const CadastroNoticiaForm({super.key, required this.service, this.onCadastrada});

  final NoticiasService service;

  /// Chamado com o id do documento criado.
  final ValueChanged<String>? onCadastrada;

  @override
  State<CadastroNoticiaForm> createState() => _CadastroNoticiaFormState();
}

class _CadastroNoticiaFormState extends State<CadastroNoticiaForm> {
  /// Limite do Firestore é 1 MiB por documento; base64 aumenta ~33%.
  static const _maxImageBytes = 600 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _resumo = TextEditingController();
  final _conteudo = TextEditingController();

  /// Link http(s) ou data URI da capa; `null` = sem imagem.
  String? _imagem;
  Uint8List? _imagemBytes; // preview quando a foto veio da galeria
  bool _saving = false;

  @override
  void dispose() {
    _titulo.dispose();
    _resumo.dispose();
    _conteudo.dispose();
    super.dispose();
  }

  void _erro(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _escolherDaGaleria() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 75);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxImageBytes) {
        throw Exception('Imagem muito grande (${bytes.length ~/ 1024} KB). Escolha uma menor que 600 KB.');
      }
      final mime = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      if (!mounted) return;
      setState(() {
        _imagemBytes = bytes;
        _imagem = 'data:$mime;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      _erro(e);
    }
  }

  Future<void> _usarLink() async {
    final c = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link da imagem'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Usar')),
        ],
      ),
    );
    c.dispose();
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _erro('O link deve começar com http:// ou https://');
      return;
    }
    if (mounted) {
      setState(() {
        _imagemBytes = null;
        _imagem = url;
      });
    }
  }

  void _removerImagem() => setState(() {
        _imagemBytes = null;
        _imagem = null;
      });

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      final id = await widget.service.cadastrar(
        titulo: _titulo.text,
        resumo: _resumo.text,
        conteudo: _conteudo.text,
        imagem: _imagem ?? '',
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _titulo.clear();
      _resumo.clear();
      _conteudo.clear();
      _removerImagem();
      messenger.showSnackBar(const SnackBar(content: Text('Notícia publicada com sucesso!')));
      widget.onCadastrada?.call(id);
    } catch (e) {
      _erro(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imagem = _imagem;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _titulo,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _resumo,
            enabled: !_saving,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Resumo', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Imagem de capa', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (imagem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _imagemBytes != null
                      ? Image.memory(_imagemBytes!, fit: BoxFit.cover)
                      : Image.network(
                          imagem,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Color(0x14000000),
                            child: Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                ),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _saving ? null : _escolherDaGaleria,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Escolher da galeria'),
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _usarLink,
                icon: const Icon(Icons.link),
                label: const Text('Usar link'),
              ),
              if (imagem != null)
                TextButton.icon(
                  onPressed: _saving ? null : _removerImagem,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _conteudo,
            enabled: !_saving,
            minLines: 6,
            maxLines: 16,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Conteúdo *',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _publicar,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_saving ? 'Publicando...' : 'Publicar notícia'),
            ),
          ),
        ],
      ),
    );
  }
}

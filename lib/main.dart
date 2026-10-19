import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_image.dart';
import 'cadastro_noticia_form.dart';
import 'firebase_options.dart';
import 'noticia_detalhe_page.dart';
import 'noticias_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  runApp(const FuncionalidadeApp());
}

class FuncionalidadeApp extends StatelessWidget {
  const FuncionalidadeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Notícias',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff123c73)),
        home: const NoticiasPage(),
      );
}

class NoticiasPage extends StatefulWidget {
  const NoticiasPage({super.key});

  @override
  State<NoticiasPage> createState() => _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {
  final _service = NoticiasService();
  DateTime? _lastBackPress;

  static String _formatDate(dynamic v) {
    if (v is! Timestamp) return '';
    final d = v.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void _abrirDetalhe(Map<String, dynamic> news) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NoticiaDetalhePage(news: news, service: _service),
        ),
      );

  void _abrirCadastro() => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (ctx) => Scaffold(
            appBar: AppBar(title: const Text('Nova notícia')),
            body: SafeArea(
              child: CadastroNoticiaForm(
                service: _service,
                onCadastrada: (_) => Navigator.of(ctx).pop(),
              ),
            ),
          ),
        ),
      );

  Future<void> _excluir(Map<String, dynamic> news) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir notícia?'),
        content: Text('"${news['titulo'] ?? ''}" será excluída definitivamente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final id = news['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await _service.excluir(id);
      }
      messenger.showSnackBar(const SnackBar(content: Text('Notícia excluída com sucesso.')));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  bool _handleBack() {
    final now = DateTime.now();
    if (_lastBackPress == null || now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pressione voltar novamente para sair'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_handleBack()) SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notícias'),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirCadastro,
          icon: const Icon(Icons.add),
          label: const Text('Nova notícia'),
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _service.streamNoticias(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Erro ao carregar dados. Verifique sua conexão.'),
                ),
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.newspaper, size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma notícia cadastrada',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque no botão abaixo para cadastrar a primeira notícia.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final news = list[i];
                final titulo = (news['titulo'] ?? '').toString().trim();
                final resumo = (news['resumo'] ?? '').toString().trim();
                final conteudo = (news['conteudo'] ?? '').toString().trim();
                final capa = (news['imagem'] ?? '').toString().trim();
                final autor = (news['autor'] ?? '').toString().trim();
                final data = _formatDate(news['criado_em']);
                final byline = [if (autor.isNotEmpty) autor, if (data.isNotEmpty) data].join(' • ');

                return Card(
                  clipBehavior: Clip.antiAlias,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _abrirDetalhe(news),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (capa.isNotEmpty)
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: AppImage(capa),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (byline.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(byline, style: theme.textTheme.bodySmall),
                                ),
                              Text(
                                titulo.isEmpty ? 'Notícia' : titulo,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (resumo.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(resumo, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                              if (resumo.isEmpty && conteudo.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(conteudo, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _abrirDetalhe(news),
                                icon: const Icon(Icons.read_more),
                                label: const Text('Ver notícia'),
                              ),
                              IconButton(
                                tooltip: 'Excluir notícia',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _excluir(news),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

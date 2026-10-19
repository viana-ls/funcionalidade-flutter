import 'package:cloud_firestore/cloud_firestore.dart';

/// Conexão com o banco de dados para gerenciar notícias.
class NoticiasService {
  NoticiasService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const colecao = 'noticias';

  /// Este app age sempre como administrador.
  static const autor = 'Administrador';

  /// Stream com a lista de notícias ordenadas das mais recentes para as mais antigas.
  Stream<List<Map<String, dynamic>>> streamNoticias() {
    return _db.collection(colecao).snapshots().map((s) {
      final list = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      int millis(dynamic v) => v is Timestamp ? v.millisecondsSinceEpoch : DateTime.now().millisecondsSinceEpoch;
      list.sort((a, b) => millis(b['criado_em']).compareTo(millis(a['criado_em'])));
      return list;
    });
  }

  /// Exclui uma notícia pelo id do documento.
  Future<void> excluir(String id) => _db.collection(colecao).doc(id).delete();

  /// Cria a notícia e devolve o id do documento.
  ///
  /// [imagem] é um link `http(s)` ou um data URI `data:image/...;base64,...`.
  /// Vazio = sem imagem.
  Future<String> cadastrar({
    required String titulo,
    required String conteudo,
    String resumo = '',
    String imagem = '',
  }) async {
    final ref = await _db.collection(colecao).add({
      'titulo': titulo.trim(),
      'resumo': resumo.trim(),
      'conteudo': conteudo.trim(),
      'imagem': imagem,
      'imagens': <Map<String, String>>[],
      'autor': autor,
      'criado_em': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}

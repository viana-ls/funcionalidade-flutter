import 'package:cloud_firestore/cloud_firestore.dart';

/// Conexão com o Cloud Firestore para cadastrar notícias.
///
/// Grava na coleção `noticias` do projeto `alumni-d1a49`, a mesma lida pelo app
/// Allumni, com o mesmo formato de documento.
class NoticiasService {
  NoticiasService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const colecao = 'noticias';

  /// Este app age sempre como administrador, então não há login.
  static const autor = 'Administrador';

  /// Cria a notícia e devolve o id do documento.
  ///
  /// [imagem] é um link `http(s)` ou um data URI `data:image/...;base64,...`
  /// (o projeto não usa Firebase Storage). Vazio = sem imagem.
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

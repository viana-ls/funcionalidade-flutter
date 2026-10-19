# funcionalidade-flutter

Funcionalidade de gerenciamento de notícias: **listagem, visualização, cadastro e exclusão**.

- **Listagem e visualização:** tela inicial com notícias em tempo real e tela de leitura completa (`lib/noticia_detalhe_page.dart`) com suporte a capa, resumo, conteúdo, fotos e legendas.
- **Componente de cadastro:** `lib/cadastro_noticia_form.dart` (`CadastroNoticiaForm`): título, resumo, conteúdo e imagem de capa (galeria ou link).
- **Conexão com o banco:** `lib/noticias_service.dart` (`NoticiasService`) conecta à coleção `noticias` do projeto `alumni-d1a49`, o mesmo banco do app Allumni. As notícias cadastradas aqui aparecem imediatamente no app Allumni.
- **Exclusão:** cada notícia pode ser excluída diretamente pela lista ou pela tela de detalhes, com confirmação.
- Não há tela de login: o app opera sempre com privilégios de administrador (`autor = "Administrador"`).
- O botão Voltar conta com proteção contra fechamento acidental (`Pressione voltar novamente para sair`).

Imagens: a foto escolhida da galeria é redimensionada e salva no próprio documento (data URI, máx. 600 KB). Também é possível informar o link direto de uma imagem.

## Como rodar

```bash
flutter pub get
flutter run
```

Pacote Android: `com.example.funcionalidade_flutter` (config em `android/app/google-services.json`).

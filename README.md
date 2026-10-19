# funcionalidade-flutter

Funcionalidade isolada do Allumni: **cadastro de notícias no Firebase**.

- **Componente Flutter:** `lib/cadastro_noticia_form.dart` (`CadastroNoticiaForm`): título, resumo, conteúdo e imagem de capa (galeria ou link).
- **Conexão com o banco:** `lib/noticias_service.dart` (`NoticiasService`) grava na coleção `noticias` do Cloud Firestore, projeto `alumni-d1a49`, o mesmo banco do app Allumni e com o mesmo formato de documento (`titulo`, `resumo`, `conteudo`, `imagem`, `imagens`, `autor`, `criado_em`). As notícias cadastradas aparecem no app Allumni.
- Não há login: o app age sempre como administrador (`autor = "Administrador"`).

Imagem: o projeto não tem Firebase Storage, então a foto da galeria é redimensionada e salva no próprio documento (data URI, máx. 600 KB).

## Rodar

```
flutter pub get
flutter run
```

Pacote Android: `com.example.funcionalidade_flutter` (registrado no projeto Firebase `alumni-d1a49`; config em `android/app/google-services.json`).

> As regras atuais do Firestore (`allow read, write: if true`) permitem escrita sem autenticação. Se for publicar, restrinja as regras.

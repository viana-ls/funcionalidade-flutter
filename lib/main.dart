import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'cadastro_noticia_form.dart';
import 'firebase_options.dart';
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
        title: 'Cadastro de notícias',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff123c73)),
        home: Scaffold(
          appBar: AppBar(title: const Text('Cadastrar notícia')),
          body: SafeArea(child: CadastroNoticiaForm(service: NoticiasService())),
        ),
      );
}

import 'package:flutter/material.dart';
import 'accueil_intro_page.dart';

void main() => runApp(const SamaBusApp());

class SamaBusApp extends StatelessWidget {
  const SamaBusApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SAMA BUS BI',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF1565C0)),
        home: const AccueilIntroPage(),
      );
}

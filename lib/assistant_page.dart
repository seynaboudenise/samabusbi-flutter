import 'package:flutter/material.dart';
import 'services/api_service.dart';

const green = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class _Message {
  final String texte;
  final bool deMoi;
  _Message(this.texte, this.deMoi);
}

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});
  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final List<_Message> _messages = [
    _Message("👋 Bonjour et bienvenue sur SAMA BUS BI !\nEn quoi puis-je vous être utile aujourd'hui ?", false),
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _envoiEnCours = false;

  Future<void> _envoyer() async {
    final texte = _controller.text.trim();
    if (texte.isEmpty || _envoiEnCours) return;

    setState(() {
      _messages.add(_Message(texte, true));
      _envoiEnCours = true;
    });
    _controller.clear();
    _scrollEnBas();

    try {
      final reponse = await ApiService.askAssistant(texte);
      setState(() => _messages.add(_Message(reponse, false)));
    } catch (e) {
      setState(() => _messages.add(_Message(
          "Désolé, je n'arrive pas à contacter le serveur. Vérifiez votre connexion.", false)));
    } finally {
      setState(() => _envoiEnCours = false);
      _scrollEnBas();
    }
  }

  void _scrollEnBas() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assistant IA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark)),
                Text('Posez vos questions sur les lignes, horaires, bus et tarifs',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _messages.length + (_envoiEnCours ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _messages.length) {
              return _bulle(_Message('...', false));
            }
            return _bulle(_messages[i]);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _envoyer(),
                decoration: const InputDecoration(
                  hintText: 'Écrivez votre question...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: dark,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _envoyer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _bulle(_Message m) => Align(
        alignment: m.deMoi ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
          decoration: BoxDecoration(
            color: m.deMoi ? dark : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            m.texte,
            style: TextStyle(color: m.deMoi ? Colors.white : dark, fontSize: 14),
          ),
        ),
      );
}
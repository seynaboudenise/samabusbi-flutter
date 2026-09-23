import 'package:flutter/material.dart';
import 'login_page.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final _slides = const [
    (
      Icons.alt_route_rounded,
      'Lignes de bus',
      'Découvrez toutes les lignes, les arrêts et les destinations du réseau de Dakar.'
    ),
    (
      Icons.location_on_rounded,
      'Localisation en temps réel',
      'Suivez les bus en direct sur la carte, où que vous soyez.'
    ),
    (
      Icons.schedule_rounded,
      'Horaires et itinéraires',
      'Consultez les horaires et trouvez le meilleur trajet pour vos déplacements.'
    ),
  ];

  void _terminer() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _terminer,
              child: const Text('Passer', style: TextStyle(color: Colors.black45)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final (icon, titre, texte) = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(color: bleu.withOpacity(.1), shape: BoxShape.circle),
                        child: Icon(icon, size: 62, color: bleu),
                      ),
                      const SizedBox(height: 36),
                      Text(titre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark)),
                      const SizedBox(height: 14),
                      Text(texte,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5)),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? bleu : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  if (_page == _slides.length - 1) {
                    _terminer();
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: bleu,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _page == _slides.length - 1 ? 'Commencer' : 'Suivant',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

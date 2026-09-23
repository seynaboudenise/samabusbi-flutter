import 'package:flutter/material.dart';
import 'login_page.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF0D1B2A);

class PresentationPage extends StatelessWidget {
  const PresentationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final features = const [
      (Icons.directions_bus_filled_rounded, 'Lignes de bus', 'Découvrez toutes les lignes, les arrêts et les destinations du réseau de Dakar.'),
      (Icons.location_on_rounded, 'Localisation en temps réel', 'Suivez les bus en direct sur la carte et consultez leur position actuelle.'),
      (Icons.schedule_rounded, 'Horaires et itinéraires', 'Consultez les horaires et trouvez le meilleur trajet pour vos déplacements.'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Passer', style: TextStyle(color: Colors.black45)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tout le réseau de transport\nde Dakar dans votre poche',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: dark, height: 1.25),
              ),
              const SizedBox(height: 28),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: bleu.withOpacity(.1), shape: BoxShape.circle),
                          child: Icon(f.$1, color: bleu, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: dark)),
                              const SizedBox(height: 4),
                              Text(f.$3, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(active: false),
                  _dot(active: true),
                  _dot(active: false),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bleu,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Suivant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot({required bool active}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: active ? 22 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: active ? bleu : Colors.black12,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

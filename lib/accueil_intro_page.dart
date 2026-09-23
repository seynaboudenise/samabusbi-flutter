import 'package:flutter/material.dart';
import 'presentation_page.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF0D1B2A);

class AccueilIntroPage extends StatelessWidget {
  const AccueilIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 320,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Image.asset(
                    'assets/images/sama_bus_hero.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre compagnon\nde transport � Dakar',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: dark, height: 1.2),
                    ),
                    const SizedBox(height: 12),
                    Container(width: 46, height: 4, decoration: BoxDecoration(color: bleu, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    const Text(
                      'Des informations en temps r�el pour des d�placements plus simples et plus rapides.',
                      style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PresentationPage()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bleu,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Commencer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(active: true),
                        _dot(active: false),
                        _dot(active: false),
                      ],
                    ),
                  ],
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

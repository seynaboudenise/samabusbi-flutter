import 'package:flutter/material.dart';

const green = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(color: green.withOpacity(.1), borderRadius: BorderRadius.circular(25)),
              child: const Icon(Icons.person_rounded, size: 42, color: green),
            ),
            const SizedBox(height: 18),
            const Text('Profil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: dark)),
            const SizedBox(height: 8),
            const Text('Compte et préférences', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            // TODO : brancher sur /api/login/ une fois la gestion de session
            // (stockage du username après connexion) mise en place.
          ],
        ),
      );
}
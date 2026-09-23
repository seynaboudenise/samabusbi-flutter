import 'package:flutter/material.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'assistant_page.dart';
import 'gestion_bus_page.dart';
import 'lignes_page.dart';
import 'utilisateurs_page.dart';
import 'login_page.dart';
import 'services/api_service.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF17221C);
const bg = Color(0xFFF5F8F6);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int tab = 0;

  final _titres = const ['', 'Gestion des bus', 'Lignes de bus', 'Utilisateurs', 'Assistant IA'];

  final _pages = const [
    HomePage(),
    GestionBusPage(),
    LignesPage(),
    UtilisateursPage(),
    AssistantPage(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: bg,
        drawerScrimColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: dark),
          title: Text(_titres[tab], style: const TextStyle(color: dark, fontWeight: FontWeight.w800, fontSize: 16)),
          actions: tab == 0
              ? [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Aucune nouvelle notification'), behavior: SnackBarBehavior.floating),
                    ),
                  ),
                ]
              : null,
        ),
        drawer: _menu(context),
        body: SafeArea(child: IndexedStack(index: tab, children: _pages)),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          backgroundColor: Colors.white,
          indicatorColor: bleu.withOpacity(.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: bleu),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.directions_bus_outlined),
              selectedIcon: Icon(Icons.directions_bus, color: bleu),
              label: 'Bus',
            ),
            NavigationDestination(
              icon: Icon(Icons.alt_route_outlined),
              selectedIcon: Icon(Icons.alt_route, color: bleu),
              label: 'Lignes',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt, color: bleu),
              label: 'Utilisateurs',
            ),
            NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy, color: bleu),
              label: 'Assistant IA',
            ),
          ],
        ),
      );

  Widget _menu(BuildContext context) => Drawer(
        backgroundColor: Colors.white,
        width: MediaQuery.of(context).size.width,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: bleu, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SAMA BUS BI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: dark)),
                        Text('Administration', style: TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: dark),
                    onPressed: () => Navigator.pop(context),
                  ),
                ]),
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              _item(context, Icons.dashboard_rounded, 'Dashboard', () {
                Navigator.pop(context);
                setState(() => tab = 0);
              }),
              _item(context, Icons.directions_bus_filled_rounded, 'Gestion des bus', () {
                Navigator.pop(context);
                setState(() => tab = 1);
              }),
              _item(context, Icons.route_rounded, 'Lignes', () {
                Navigator.pop(context);
                setState(() => tab = 2);
              }),
              _item(context, Icons.map_rounded, 'Localisation GPS', () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
              }),
              _item(context, Icons.people_alt_rounded, 'Utilisateurs', () {
                Navigator.pop(context);
                setState(() => tab = 3);
              }),
              _item(context, Icons.smart_toy_rounded, 'Assistant IA', () {
                Navigator.pop(context);
                setState(() => tab = 4);
              }),
              const Spacer(),
              const Divider(height: 1),
              _item(context, Icons.logout_rounded, 'Déconnexion', () {
                Navigator.pop(context);
                _confirmerDeconnexion(context);
              }, color: Colors.redAccent),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );

  Widget _item(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
        leading: Icon(icon, color: color ?? bleu),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? dark)),
        onTap: onTap,
      );

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
        title: const Text('Déconnexion', textAlign: TextAlign.center),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ApiService.authToken = null;
                  ApiService.currentUsername = null;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler', style: TextStyle(color: dark)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
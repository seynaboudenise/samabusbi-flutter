import 'package:flutter/material.dart';
import 'services/api_service.dart';

const green = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class UtilisateursPage extends StatefulWidget {
  const UtilisateursPage({super.key});
  @override
  State<UtilisateursPage> createState() => _UtilisateursPageState();
}

class _UtilisateursPageState extends State<UtilisateursPage> {
  List<dynamic> utilisateurs = [];
  bool loading = true;
  String? erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      loading = true;
      erreur = null;
    });
    try {
      final data = await ApiService.getUtilisateurs();
      setState(() {
        utilisateurs = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        erreur = 'Accès refusé ou serveur injoignable.\nCette page est réservée aux administrateurs connectés.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs', style: TextStyle(color: dark, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: dark),
      ),
      backgroundColor: const Color(0xFFF5F8F6),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : erreur != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 48, color: Colors.black38),
                        const SizedBox(height: 12),
                        Text(erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: green,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: utilisateurs.length,
                    itemBuilder: (context, i) {
                      final u = utilisateurs[i];
                      final estAdmin = u['is_admin'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Row(children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: estAdmin ? green : Colors.blueGrey,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              estAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (u['nom'] != null && '${u['nom']}'.isNotEmpty) ? u['nom'] : u['username'],
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: dark),
                                ),
                                Text(u['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                Text('Inscrit le ${u['date_inscription']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
                              ],
                            ),
                          ),
                          if (estAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: green.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Admin', style: TextStyle(fontSize: 10, color: green, fontWeight: FontWeight.w800)),
                            ),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
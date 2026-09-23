import 'package:flutter/material.dart';
import 'services/api_service.dart';

const green = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class GestionBusPage extends StatefulWidget {
  const GestionBusPage({super.key});
  @override
  State<GestionBusPage> createState() => _GestionBusPageState();
}

class _GestionBusPageState extends State<GestionBusPage> {
  List<dynamic> bus = [];
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
      final data = await ApiService.getBus();
      setState(() {
        bus = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        erreur = 'Impossible de charger les bus.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des bus', style: TextStyle(color: dark, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: dark),
      ),
      backgroundColor: const Color(0xFFF5F8F6),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: green))
          : erreur != null
              ? Center(child: Text(erreur!, style: const TextStyle(color: Colors.black54)))
              : RefreshIndicator(
                  onRefresh: _charger,
                  color: green,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: bus.length,
                    itemBuilder: (context, i) {
                      final b = bus[i];
                      final enService = b['statut'] == 'En service';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: enService ? green : Colors.grey,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text('${b['numero']}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ligne ${b['ligne']}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: dark)),
                                    Text(b['chauffeur'] ?? '',
                                        style: const TextStyle(fontSize: 12, color: Colors.black45)),
                                  ],
                                ),
                              ),
                              Text(
                                b['statut'] ?? '',
                                style: TextStyle(
                                  color: enService ? green : Colors.redAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ]),
                            if (b['prochain_arret'] != null && '${b['prochain_arret']}'.isNotEmpty) ...[
                              const Divider(height: 20),
                              Row(children: [
                                const Icon(Icons.location_on_rounded, size: 16, color: green),
                                const SizedBox(width: 6),
                                Text('Prochain arrêt : ${b['prochain_arret']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              ]),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
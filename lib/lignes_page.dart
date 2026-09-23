import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'ligne_detail_page.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class LignesPage extends StatefulWidget {
  const LignesPage({super.key});
  @override
  State<LignesPage> createState() => _LignesPageState();
}

class _LignesPageState extends State<LignesPage> {
  List<dynamic> lignes = [];
  bool loading = true;
  String? erreur;
  String recherche = '';

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
      final data = await ApiService.getLignes();
      setState(() {
        lignes = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        erreur = 'Impossible de charger les lignes.';
        loading = false;
      });
    }
  }

  List<dynamic> get _filtres {
    if (recherche.trim().isEmpty) return lignes;
    final q = recherche.toLowerCase();
    return lignes.where((l) {
      return '${l['numero']}'.toLowerCase().contains(q) ||
          '${l['depart']}'.toLowerCase().contains(q) ||
          '${l['arrivee']}'.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: bleu));
    if (erreur != null) return Center(child: Text(erreur!, style: const TextStyle(color: Colors.black54)));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: TextField(
            onChanged: (v) => setState(() => recherche = v),
            decoration: const InputDecoration(
              hintText: 'Rechercher une ligne...',
              prefixIcon: Icon(Icons.search_rounded, color: bleu),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _charger,
          color: bleu,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: _filtres.length,
            itemBuilder: (context, i) {
              final l = _filtres[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LigneDetailPage(ligne: l)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: bleu, borderRadius: BorderRadius.circular(14)),
                        child: Center(
                          child: Text('${l['numero']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l['depart']} → ${l['arrivee']}', style: const TextStyle(fontWeight: FontWeight.w800, color: dark)),
                            const SizedBox(height: 4),
                            Text('Tarif : ${l['tarif']} FCFA', style: const TextStyle(fontSize: 12, color: Colors.black45)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.black26),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ]);
  }
}

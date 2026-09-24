import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/api_service.dart';
import 'map_page.dart';

const bleu = Color(0xFF1565C0);
const vert = Color(0xFF2E7D32);
const violet = Color(0xFF6A1B9A);
const orange = Color(0xFFEF6C00);
const dark = Color(0xFF17221C);
const LatLng kDakarCenter = LatLng(14.7167, -17.4677);

const _mois = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? stats;
  List<dynamic> busCirculation = [];
  List<dynamic> horaires = [];
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
      final results = await Future.wait([
        ApiService.getStatistiques(),
        ApiService.getBusEnCirculation(),
        ApiService.getHoraires(),
      ]);
      setState(() {
        stats = results[0] as Map<String, dynamic>;
        busCirculation = results[1] as List<dynamic>;
        horaires = (results[2] as List<dynamic>).take(2).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        erreur = 'Impossible de charger les données.\nVérifiez que le serveur Django est bien lancé.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: bleu));
    }
    if (erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.black38),
              const SizedBox(height: 12),
              Text(erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _charger,
                style: ElevatedButton.styleFrom(backgroundColor: bleu),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    // La mini-carte est hors de la zone qui défile : elle ne peut plus jamais bloquer le scroll.
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: _header(),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _miniCarte(),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _charger,
          color: bleu,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            children: [
              _statsGrid(),
              const SizedBox(height: 22),
              _title('Prochains trajets', ''),
              const SizedBox(height: 12),
              _prochainsTrajets(),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _header() {
    final nom = ApiService.currentUsername ?? 'Utilisateur';
    final now = DateTime.now();
    final dateTxt = "Aujourd'hui, ${now.day} ${_mois[now.month - 1]} ${now.year}";
    return Row(children: [
      Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(color: bleu, shape: BoxShape.circle),
        child: Center(
          child: Text(
            nom.isNotEmpty ? nom[0].toUpperCase() : 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bonjour,', style: TextStyle(color: Colors.black54, fontSize: 13)),
            Text(nom, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: dark)),
            const SizedBox(height: 2),
            Text(dateTxt, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
    ]);
  }

  Widget _miniCarte() {
    final markers = busCirculation.where((b) => b['latitude'] != null && b['longitude'] != null).map((b) {
      final lat = double.tryParse('${b['latitude']}') ?? 0;
      final lng = double.tryParse('${b['longitude']}') ?? 0;
      return Marker(
        point: LatLng(lat, lng),
        width: 34,
        height: 34,
        child: Container(
          decoration: BoxDecoration(color: bleu, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
          child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 16),
        ),
      );
    }).toList();

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage())),
      child: Container(
        height: 150,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        // IgnorePointer : cette mini-carte est juste un aperçu visuel, elle ne capte aucun
        // geste (ni zoom, ni molette) — donc rien ne peut interférer avec le défilement de la page.
        child: IgnorePointer(
          child: Stack(children: [
            FlutterMap(
              options: const MapOptions(initialCenter: kDakarCenter, initialZoom: 11),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.samabus.app',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.95), borderRadius: BorderRadius.circular(12)),
                child: Text('${busCirculation.length} bus suivis',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: dark)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _statsGrid() {
    final s = stats ?? {};
    final items = [
      ('Bus en service', '${s['bus_en_service'] ?? 0}', Icons.directions_bus_filled_rounded),
      ('Lignes de bus', '${s['total_lignes'] ?? 0}', Icons.alt_route_rounded),
      ('Utilisateurs', '${s['total_utilisateurs'] ?? '—'}', Icons.people_alt_rounded),
      ('Assistant IA', 'Actif', Icons.smart_toy_rounded),
    ];
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 100,
      ),
      children: items
          .map((it) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(it.$3, color: bleu),
                    const Spacer(),
                    Text(it.$2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark)),
                    Text(it.$1, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _title(String a, String b) => Row(children: [
        Expanded(child: Text(a, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: dark))),
      ]);

  Widget _prochainsTrajets() {
    if (horaires.isEmpty) {
      return const Text('Aucun horaire enregistré.', style: TextStyle(color: Colors.black45));
    }
    final maintenant = TimeOfDay.now();
    return Column(
      children: horaires.map((h) {
        final heureStr = '${h['heure_passage']}'; // format "HH:MM:SS"
        final parts = heureStr.split(':');
        final heureH = int.tryParse(parts[0]) ?? 0;
        final heureM = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final minutesTrajet = heureH * 60 + heureM;
        final minutesMaintenant = maintenant.hour * 60 + maintenant.minute;
        final enCours = (minutesMaintenant - minutesTrajet).abs() <= 20;
        final passe = minutesTrajet < minutesMaintenant - 20;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bleu.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.location_on_rounded, color: bleu, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ligne ${h['ligne_numero']} — ${h['arret']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: dark, fontSize: 13)),
                  Text(heureStr.substring(0, 5), style: const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (enCours ? vert : (passe ? Colors.grey : orange)).withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                enCours ? 'En cours' : (passe ? 'Passé' : 'À venir'),
                style: TextStyle(
                  color: enCours ? vert : (passe ? Colors.grey.shade600 : orange),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

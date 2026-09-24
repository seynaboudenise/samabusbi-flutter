import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/api_service.dart';

const bleu = Color(0xFF1565C0);
const vert = Color(0xFF2E7D32);
const orange = Color(0xFFEF6C00);
const dark = Color(0xFF0D1B2A);

/// Distance approximative en mètres entre deux points GPS (formule haversine).
double _distanceMetres(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * (3.141592653589793 / 180);
  final dLng = (b.longitude - a.longitude) * (3.141592653589793 / 180);
  final la1 = a.latitude * (3.141592653589793 / 180);
  final la2 = b.latitude * (3.141592653589793 / 180);
  final h = (sin(dLat / 2) * sin(dLat / 2)) +
      cos(la1) * cos(la2) * (sin(dLng / 2) * sin(dLng / 2));
  return 2 * r * asin(sqrt(h.clamp(0, 1)));
}

/// Trouve l'index du point du tracé le plus proche d'une position donnée.
int _indexLePlusProche(List<LatLng> route, LatLng point) {
  int meilleurIndex = 0;
  double meilleureDistance = double.infinity;
  for (int i = 0; i < route.length; i++) {
    final d = _distanceMetres(route[i], point);
    if (d < meilleureDistance) {
      meilleureDistance = d;
      meilleurIndex = i;
    }
  }
  return meilleurIndex;
}

/// Distance cumulée le long du tracé entre deux index (0 si l'arrêt est déjà derrière le bus).
double _distanceLeLongDuTrace(List<LatLng> route, int indexDepart, int indexArrivee) {
  if (indexArrivee <= indexDepart) return 0;
  double total = 0;
  for (int i = indexDepart; i < indexArrivee; i++) {
    total += _distanceMetres(route[i], route[i + 1]);
  }
  return total;
}

class LigneDetailPage extends StatefulWidget {
  final Map<String, dynamic> ligne;
  const LigneDetailPage({super.key, required this.ligne});

  @override
  State<LigneDetailPage> createState() => _LigneDetailPageState();
}

class _LigneDetailPageState extends State<LigneDetailPage> {
  List<LatLng> _itineraire = [];
  List<dynamic> _arrets = [];
  List<dynamic> _horaires = [];
  dynamic _bus;
  bool _loading = true;
  String? _erreurItineraire;
  Timer? _timer;
  final MapController _mapController = MapController();

  String get _numero => '${widget.ligne['numero']}';

  double get _vitesseBus =>
      _bus != null ? (double.tryParse('${_bus['vitesse_actuelle'] ?? 0}') ?? 0) : 0;

  /// true seulement si un bus est trouvé ET qu'il est réellement en train de rouler.
  bool get _busEnCirculation => _bus != null && _vitesseBus > 0;

  @override
  void initState() {
    super.initState();
    _chargerItineraireEtHoraires();
    _chargerBus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _chargerBus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _chargerItineraireEtHoraires() async {
    try {
      final itin = await ApiService.getItineraire(_numero);
      final points = (itin['points'] as List)
          .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
          .toList();
      final arrets = (itin['arrets'] as List?) ?? [];
      final horaires = await ApiService.getHoraires(ligne: _numero);
      if (!mounted) return;
      setState(() {
        _itineraire = points;
        _arrets = arrets;
        _horaires = horaires;
        _loading = false;
      });
      if (points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(20)),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreurItineraire = "Itinéraire réel indisponible pour le moment.";
        _loading = false;
      });
    }
  }

  Future<void> _chargerBus() async {
    try {
      final busList = await ApiService.getBusEnCirculation();
      final match = busList.firstWhere(
        (b) => RegExp(r'\d+').firstMatch('${b['ligne']}')?.group(0) == _numero,
        orElse: () => null,
      );
      if (!mounted) return;
      setState(() => _bus = match);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final depart = widget.ligne['depart'] ?? '';
    final arrivee = widget.ligne['arrivee'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: dark),
        title: Text('Ligne $_numero', style: const TextStyle(color: dark, fontWeight: FontWeight.w800)),
      ),
      body: Column(children: [
        _enTete(depart, arrivee),
        Expanded(child: _carte()),
        _bas(),
      ]),
    );
  }

  Widget _enTete(String depart, String arrivee) {
    // Trois états possibles, cohérents avec le reste de l'application :
    // - Aucun bus trouvé pour cette ligne -> Hors ligne
    // - Bus trouvé mais vitesse = 0 -> À l'arrêt
    // - Bus trouvé avec vitesse > 0 -> En circulation
    final String statutTexte = _bus == null ? 'Hors ligne' : (_busEnCirculation ? 'En circulation' : 'À l\'arrêt');
    final Color statutCouleur = _bus == null ? Colors.grey : (_busEnCirculation ? vert : Colors.orange.shade700);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: bleu, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$depart  →  $arrivee',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: dark, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                _bus != null ? "Dernière mise à jour : ${_formatHeure(_bus['derniere_maj'])}" : "Aucun bus en circulation actuellement",
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statutCouleur.withOpacity(.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(color: statutCouleur, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(statutTexte,
                style: TextStyle(color: statutCouleur, fontWeight: FontWeight.w800, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }


  /// Garde uniquement les arrêts qui possèdent de vraies coordonnées GPS.
  List<dynamic> _arretsAvecCoordonnees() {
    return _arrets.where((a) {
      final lat = double.tryParse('${a['lat']}');
      final lng = double.tryParse('${a['lng']}');
      return lat != null &&
          lng != null &&
          lat != 0 &&
          lng != 0 &&
          lat!.abs() <= 90 &&
          lng!.abs() <= 180;
    }).toList();
  }

  /// Sélectionne au maximum 4 arrêts répartis sur le trajet.
  List<dynamic> _arretsPrincipaux() {
    final valides = _arretsAvecCoordonnees();

    if (valides.length <= 4) {
      return valides;
    }

    final indices = [
      0,
      ((valides.length - 1) / 3).round(),
      (((valides.length - 1) * 2) / 3).round(),
      valides.length - 1,
    ];

    final indicesUniques = indices.toSet().toList()..sort();
    return indicesUniques.map((index) => valides[index]).toList();
  }

  Widget _carte() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: bleu));

    LatLng centre = const LatLng(14.7167, -17.4677);
    if (_itineraire.isNotEmpty) centre = _itineraire[_itineraire.length ~/ 2];

    final busPoint = (_bus != null && _bus['latitude'] != null && _bus['longitude'] != null)
        ? LatLng(double.parse('${_bus['latitude']}'), double.parse('${_bus['longitude']}'))
        : null;

    // Position du bus le long du tracé, pour calculer la distance restante jusqu'à chaque arrêt
    int? busIndexSurTrace;
    if (busPoint != null && _itineraire.isNotEmpty) {
      busIndexSurTrace = _indexLePlusProche(_itineraire, busPoint);
    }
    final vitesseMs = (_bus != null && _bus['vitesse_actuelle'] != null)
        ? (double.tryParse('${_bus['vitesse_actuelle']}') ?? 0) / 3.6
        : 0.0;

    final arretsPrincipaux = _arretsPrincipaux();

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: centre, initialZoom: 12),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.samabus.app',
          ),
          if (_itineraire.isNotEmpty)
            PolylineLayer(polylines: [
              Polyline(points: _itineraire, color: bleu, strokeWidth: 5),
            ]),
          MarkerLayer(markers: [
            for (final a in _arretsPrincipaux())
              Marker(
                point: LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble()),
                width: 100,
                height: 58,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Builder(builder: (context) {
                    String? etaTexte;
                    if (busIndexSurTrace != null && vitesseMs > 1 && _itineraire.isNotEmpty) {
                      final arretPoint = LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble());
                      final arretIndex = _indexLePlusProche(_itineraire, arretPoint);
                      final distance = _distanceLeLongDuTrace(_itineraire, busIndexSurTrace, arretIndex);
                      if (arretIndex > busIndexSurTrace) {
                        final minutes = (distance / vitesseMs / 60).round();
                        etaTexte = minutes < 1 ? '<1 min' : '$minutes min';
                      }
                    }
                    if (etaTexte == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: bleu, borderRadius: BorderRadius.circular(6)),
                      child: Text(etaTexte, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  }),
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: bleu, width: 3)),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(6)),
                    child: Text('${a['nom']}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: dark)),
                  ),
                ]),
              ),
            if (busPoint != null)
              Marker(
                point: busPoint,
                width: 70,
                height: 70,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: vert, borderRadius: BorderRadius.circular(8)),
                    child: const Text('Position actuelle', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: vert, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                    child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 18),
                  ),
                ]),
              ),
          ]),
        ],
      ),

      if (arretsPrincipaux.length < 4)
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.94),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seuls ${arretsPrincipaux.length} arrêt(s) possèdent des coordonnées GPS valides.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: dark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

      if (_erreurItineraire != null)
        Positioned(
          top: 12, left: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.95), borderRadius: BorderRadius.circular(12)),
            child: Text(_erreurItineraire!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
        ),
    ]);
  }

  Widget _bas() {
    final arretsPrincipaux = _arretsPrincipaux();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 285),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.route_rounded, color: bleu, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Arrêts principaux',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: dark,
                    ),
                  ),
                ),
                Text(
                  '${arretsPrincipaux.length} arrêt(s)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (arretsPrincipaux.isEmpty)
              const Text(
                'Aucun arrêt ne possède encore de coordonnées GPS valides.',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              )
            else
              SizedBox(
                height: 66,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: arretsPrincipaux.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final arret = arretsPrincipaux[index];
                    final estDepart = index == 0;
                    final estArrivee = index == arretsPrincipaux.length - 1;

                    return Container(
                      width: 150,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: bleu.withOpacity(.12)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: estDepart || estArrivee ? orange : bleu,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${arret['nom'] ?? 'Arrêt'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: dark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
            if (_bus != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: bleu, size: 21),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Prochain arrêt',
                      style: TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ),
                  Text(
                    _busEnCirculation ? '${_bus['eta_minutes'] ?? '—'} min' : 'Terminus',
                    style: const TextStyle(
                      color: vert,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                (_bus['prochain_arret'] != null && '${_bus['prochain_arret']}'.isNotEmpty)
                    ? '${_bus['prochain_arret']}'
                    : (_busEnCirculation ? 'En calcul...' : 'Terminus atteint'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: dark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _statCarte(
                      Icons.speed_rounded,
                      'Vitesse actuelle',
                      _busEnCirculation ? '${_bus['vitesse_actuelle']} km/h' : 'À l\'arrêt',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCarte(
                      Icons.people_alt_rounded,
                      'Places',
                      '${_bus['places_occupees'] ?? 0}/${_bus['capacite'] ?? '—'}',
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aucun bus en circulation actuellement. Les informations de position et d’ETA apparaîtront lorsqu’un bus sera actif.',
                        style: TextStyle(
                          fontSize: 11,
                          color: dark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            _lignesHoraires(),
          ],
        ),
      ),
    );
  }

  Widget _statCarte(IconData icon, String label, String valeur) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF5F8F6), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(icon, color: bleu, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                Text(valeur, style: const TextStyle(fontWeight: FontWeight.w800, color: dark)),
              ],
            ),
          ),
        ]),
      );

  Widget _lignesHoraires() {
    if (_horaires.isEmpty) {
      return const Text('Aucun horaire enregistré pour cette ligne.', style: TextStyle(color: Colors.black45, fontSize: 12));
    }
    final maintenant = TimeOfDay.now();
    final minutesMaintenant = maintenant.hour * 60 + maintenant.minute;

    // Trie les horaires par heure et détermine le premier arrêt encore à venir
    final tries = List<dynamic>.from(_horaires);
    int minutesDe(dynamic h) {
      final parts = '${h['heure_passage']}'.split(':');
      return (int.tryParse(parts[0]) ?? 0) * 60 + (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    }
    tries.sort((a, b) => minutesDe(a).compareTo(minutesDe(b)));
    final indexProchain = tries.indexWhere((h) => minutesDe(h) >= minutesMaintenant);

    return SizedBox(
      height: 62,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tries.length,
        itemBuilder: (context, i) {
          final h = tries[i];
          final heureStr = '${h['heure_passage']}';
          final estProchain = i == indexProchain;
          final estPasse = indexProchain == -1 ? true : i < indexProchain;
          final estDernier = i == tries.length - 1;

          final couleur = estProchain ? orange : (estPasse ? bleu : Colors.black26);

          return IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: estProchain ? 16 : 12,
                      height: estProchain ? 16 : 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: estPasse || estProchain ? couleur : Colors.white,
                        border: Border.all(color: couleur, width: 2),
                        boxShadow: estProchain ? [BoxShadow(color: orange.withOpacity(.3), blurRadius: 6, spreadRadius: 2)] : null,
                      ),
                    ),
                    if (!estDernier)
                      Container(width: 40, height: 2, color: estPasse ? bleu : Colors.black12),
                  ]),
                  const SizedBox(height: 6),
                  Text('${h['arret']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: estProchain ? orange : dark)),
                  Text(estProchain ? 'Prochain arrêt' : (estPasse ? 'Passé' : heureStr.substring(0, 5)),
                      style: TextStyle(fontSize: 9, color: estProchain ? orange : Colors.black45)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatHeure(dynamic iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse('$iso').toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}

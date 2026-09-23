import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'services/api_service.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF17221C);
const LatLng kDakarCenter = LatLng(14.7167, -17.4677);

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  Map<String, LatLng> _displayPositions = {};
  Map<String, LatLng> _fromPositions = {};
  Map<String, LatLng> _toPositions = {};
  Map<String, dynamic> _busData = {};

  late final AnimationController _animController;
  final MapController _mapController = MapController();
  Timer? _pollTimer;
  bool loading = true;
  bool _premierChargement = true;
  String? erreur;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))
      ..addListener(_interpoler);
    _charger();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _charger());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final data = await ApiService.getBusEnCirculation();
      final nouvellesPositions = <String, LatLng>{};
      final nouvellesDonnees = <String, dynamic>{};

      for (final b in data) {
        if (b['latitude'] == null || b['longitude'] == null) continue;
        final numero = '${b['numero']}';
        final lat = double.tryParse('${b['latitude']}') ?? 0;
        final lng = double.tryParse('${b['longitude']}') ?? 0;
        nouvellesPositions[numero] = LatLng(lat, lng);
        nouvellesDonnees[numero] = b;
      }

      if (!mounted) return;
      setState(() {
        _fromPositions = Map.from(_displayPositions);
        for (final numero in nouvellesPositions.keys) {
          _fromPositions.putIfAbsent(numero, () => nouvellesPositions[numero]!);
        }
        _toPositions = nouvellesPositions;
        _busData = nouvellesDonnees;
        loading = false;
        erreur = null;
      });
      _animController.forward(from: 0);

      if (_premierChargement && nouvellesPositions.isNotEmpty) {
        _premierChargement = false;
        _recentrerSurLesBus(nouvellesPositions.values.toList());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erreur = 'Connexion au serveur impossible.';
        loading = false;
      });
    }
  }

  void _recentrerSurLesBus(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  void _interpoler() {
    final t = Curves.easeInOut.transform(_animController.value);
    final resultat = <String, LatLng>{};
    for (final numero in _toPositions.keys) {
      final from = _fromPositions[numero] ?? _toPositions[numero]!;
      final to = _toPositions[numero]!;
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;
      resultat[numero] = LatLng(lat, lng);
    }
    setState(() => _displayPositions = resultat);
  }

  @override
  Widget build(BuildContext context) {
    final markers = _displayPositions.entries.map((entry) {
      final numero = entry.key;
      final point = entry.value;
      final b = _busData[numero];
      return Marker(
        point: point,
        width: 46,
        height: 46,
        child: GestureDetector(
          onTap: () => _afficherDetail(b),
          child: Container(
            decoration: BoxDecoration(
              color: bleu,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 14),
                Text(numero, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 9)),
              ],
            ),
          ),
        ),
      );
    }).toList();

    return Stack(children: [
      FlutterMap(
        mapController: _mapController,
        options: const MapOptions(initialCenter: kDakarCenter, initialZoom: 12),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.samabus.app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      Positioned(
        top: 14,
        left: 14,
        right: 14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 12)],
          ),
          child: Row(children: [
            const Icon(Icons.gps_fixed_rounded, color: bleu, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loading ? 'Chargement...' : erreur ?? '${_displayPositions.length} bus en circulation',
                style: const TextStyle(fontWeight: FontWeight.w700, color: dark, fontSize: 13, decoration: TextDecoration.none),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.center_focus_strong_rounded, color: bleu),
              tooltip: 'Recentrer sur les bus',
              onPressed: () => _recentrerSurLesBus(_toPositions.values.toList()),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: bleu),
              onPressed: _charger,
            ),
          ]),
        ),
      ),
    ]);
  }

  void _afficherDetail(dynamic b) {
    if (b == null) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bus ${b['numero']} — Ligne ${b['ligne']}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: dark)),
            const SizedBox(height: 12),
            _ligneInfo(Icons.person_rounded, 'Chauffeur', b['chauffeur'] ?? '—'),
            _ligneInfo(Icons.location_on_rounded, 'Prochain arrêt', b['prochain_arret'] ?? '—'),
            _ligneInfo(Icons.timer_rounded, 'Arrivée estimée',
                b['eta_minutes'] != null ? '${b['eta_minutes']} min' : '—'),
            _ligneInfo(Icons.speed_rounded, 'Vitesse actuelle',
                b['vitesse_actuelle'] != null ? '${b['vitesse_actuelle']} km/h' : '—'),
            _ligneInfo(Icons.people_alt_rounded, 'Places',
                '${b['places_occupees'] ?? 0}/${b['capacite'] ?? '—'}'),
            _ligneInfo(
              Icons.warning_amber_rounded,
              'Retard',
              (b['retard_minutes'] ?? 0) > 0 ? '${b['retard_minutes']} min' : 'Aucun',
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligneInfo(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: bleu),
          const SizedBox(width: 10),
          Text('$label : ', style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: dark)),
        ]),
      );
}

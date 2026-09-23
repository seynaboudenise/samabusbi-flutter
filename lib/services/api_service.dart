import 'dart:convert';
import 'package:http/http.dart' as http;

const String kApiBaseUrl = 'https://vice-remnant-frugally.ngrok-free.dev/api/';

class ApiService {
  static String? authToken;
  static String? currentUsername;

  static Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('$kApiBaseUrl$path').replace(queryParameters: query);

  static Map<String, String> get _headersBase => {
        'ngrok-skip-browser-warning': 'true',
      };

  static Map<String, String> get _headersAuth => {
        ..._headersBase,
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Token $authToken',
      };

  static Future<Map<String, dynamic>> getStatistiques() async {
    final res = await http.get(_u('statistiques/'), headers: _headersBase);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getBus() async {
    final res = await http.get(_u('bus/'), headers: _headersBase);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<List<dynamic>> getBusEnCirculation() async {
    final res = await http.get(_u('bus-en-circulation/'), headers: _headersBase);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<List<dynamic>> getLignes() async {
    final res = await http.get(_u('lignes/'), headers: _headersBase);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<List<dynamic>> getHoraires({String? ligne}) async {
    final res = await http.get(_u('horaires/', ligne != null ? {'ligne': ligne} : null), headers: _headersBase);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  static Future<List<dynamic>> getUtilisateurs() async {
    final res = await http.get(_u('utilisateurs/'), headers: _headersAuth);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
  }

  /// GET /api/lignes/<numero>/itineraire/ — vrai tracé routier (OSRM) de la ligne
  static Future<Map<String, dynamic>> getItineraire(String numero) async {
    final res = await http.get(_u('lignes/$numero/itineraire/'), headers: _headersBase);
    _checkOk(res);
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static Future<String> askAssistant(String message) async {
    final res = await http.post(
      _u('assistant/'),
      headers: _headersAuth,
      body: jsonEncode({'message': message}),
    );
    _checkOk(res);
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return data['reponse'] as String? ?? 'Pas de réponse.';
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      _u('login/'),
      headers: _headersAuth,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (data['success'] == true) {
      if (data['token'] != null) authToken = data['token'] as String;
      currentUsername = data['username'] as String?;
    }
    return data;
  }

  static Future<Map<String, dynamic>> inscription(String nom, String email, String password) async {
    final res = await http.post(
      _u('inscription/'),
      headers: _headersAuth,
      body: jsonEncode({'nom': nom, 'email': email, 'password': password}),
    );
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  static void _checkOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Erreur serveur (${res.statusCode}) : ${res.body}');
    }
  }
}

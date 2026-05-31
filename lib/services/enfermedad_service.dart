import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/envs.dart';
import '../models/enfermedad_model.dart';
import '../models/lote_model.dart';
import 'auth_service.dart';

class EnfermedadService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<LoteModel>> getLotesActivos() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/lotes/'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data
          .map((j) => LoteModel.fromJson(j))
          .where((l) => l.estado != 'Finalizado')
          .toList();
    }
    throw Exception('Error al obtener lotes: ${response.statusCode}');
  }

  Future<List<EnfermedadModel>> getEnfermedades({int? loteId}) async {
    final uri = loteId != null
        ? Uri.parse('$_baseUrl/sanitario/enfermedades/?lote=$loteId')
        : Uri.parse('$_baseUrl/sanitario/enfermedades/');

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((j) => EnfermedadModel.fromJson(j)).toList();
    }
    throw Exception('Error al obtener enfermedades: ${response.statusCode}');
  }

  Future<EnfermedadModel> registrarEnfermedad(EnfermedadModel model) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sanitario/enfermedades/'),
      headers: await _headers(),
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return EnfermedadModel.fromJson(data['data'] ?? data);
    }

    try {
      final err = jsonDecode(response.body);
      final msg =
          err['detail'] ??
          err['lote']?.first ??
          err['enfermedad_sintoma']?.first ??
          err['cantidad_aves_afectadas']?.first ??
          'Error al guardar';
      throw Exception(msg);
    } catch (_) {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }
}

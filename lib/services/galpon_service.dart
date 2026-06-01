import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/galpon_model.dart';
import 'auth_service.dart';

class GalponService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<GalponModel>> getGalpones() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/galpones/'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((j) => GalponModel.fromJson(j)).toList();
    }
    throw Exception('Error al obtener galpones: ${response.statusCode}');
  }
}

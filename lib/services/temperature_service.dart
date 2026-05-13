import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/envs.dart';
import '../data/models/temperature_entry_model.dart';
import '../models/galpon_model.dart';
import 'auth_service.dart';

class TemperatureService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<GalponModel>> getGalpones() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/galpones/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => GalponModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener galpones: ${response.statusCode}');
      }
    } catch (e) {
      print('Excepción en getGalpones de TemperatureService: $e');
      rethrow;
    }
  }

  Future<void> postTemperature(TemperatureEntryModel entry) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/temperatura/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(entry.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al registrar la temperatura: ${response.body}');
      }
    } catch (e) {
      print('Excepción en postTemperature: $e');
      rethrow;
    }
  }
}

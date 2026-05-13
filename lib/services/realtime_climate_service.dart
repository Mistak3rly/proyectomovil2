// CU09: Monitorear temperatura en tiempo real
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/entities/realtime_climate.dart';
import '../models/galpon_model.dart';
import '../config/envs.dart';
import 'auth_service.dart';

class RealtimeClimateService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  // Obtenemos los galpones activos para los filtros de la pantalla
  Future<List<GalponModel>> getGalpones() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/galpones/'), // Asumimos que tienes este endpoint para la lista del dropdown
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => GalponModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error al obtener galpones: $e');
      // Devuelve algunos de prueba si falla la API
      return [
        GalponModel(id: 1, nombre: 'Galpón A (Fallback)'),
        GalponModel(id: 2, nombre: 'Galpón B (Fallback)'),
      ];
    }
  }

  // Stream que hace HTTP Polling cada 5 segundos al backend
  Stream<List<RealtimeClimate>> getClimateStream() async* {
    while (true) {
      try {
        final token = await _authService.getToken();
        final response = await http.get(
          Uri.parse('$_baseUrl/temperatura/tiempo-real/'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          // El backend devuelve una lista de diccionarios JSON con las temperaturas
          final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          final climates = data.map((json) => RealtimeClimate.fromJson(json)).toList();
          
          yield climates;
        } else {
          print('Error del servidor: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Excepción conectando al socket simulado (API): $e');
      }

      // El backend menciona que el frontend debe llamar cada 5 segundos
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  // CU10: Generación de alertas por cambios de temperatura
  Future<List<RealtimeClimate>> getAlertas() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/temperatura/alertas/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => RealtimeClimate.fromJson(json)).toList();
      } else {
        print('Error al obtener alertas: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Excepción al obtener alertas: $e');
      return [];
    }
  }
}

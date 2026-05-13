import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/envs.dart';
import '../models/lote_model.dart';
import '../domain/entities/mortality_record.dart';
import '../domain/entities/tratamiento_model.dart';
import '../domain/entities/vacunacion_model.dart';
import 'auth_service.dart';

class SanidadService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  // Obtener lotes activos desde el backend
  Future<List<LoteModel>> getActiveLots() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/lotes/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => LoteModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener lotes: ${response.statusCode}');
      }
    } catch (e) {
      print('Aviso: Error de red o endpoint no listo ($e)');
      rethrow; // Lanzar el error real para que la UI sepa que falló
    }
  }

  // CU13: Registrar mortandad
  Future<void> postMortality(MortalityRecord record) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/mortandad/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al registrar mortandad: ${response.body}');
    }
  }

  // CU13: Obtener registros de mortandad
  Future<List<MortalityRecord>> getMortalityRecords(int? lotId) async {
    final token = await _authService.getToken();
    final uri = lotId != null 
        ? Uri.parse('$_baseUrl/mortandad/?lote=$lotId')
        : Uri.parse('$_baseUrl/mortandad/');
        
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MortalityRecord.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener mortandad: ${response.statusCode}');
    }
  }
  
  // CU14: Gráficos de análisis (Usar historial real)
  Future<List<MortalityRecord>> getMockHistoryForAnalysis(int lotId) async {
    try {
      // Ya no usamos mock, traemos el historial real del lote para los gráficos
      return await getMortalityRecords(lotId);
    } catch (e) {
      print('Error al obtener historial para gráficos: $e');
      return [];
    }
  }

  Future<void> postTratamiento(TratamientoModel t) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> postVacunacion(VacunacionModel v) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

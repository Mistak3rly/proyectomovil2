import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/envs.dart';
import '../models/alimentacion_model.dart';
import 'auth_service.dart';

class AlimentacionService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  // CU12: Consultar historial de alimentación
  Future<List<AlimentacionModel>> getAlimentacion({
    int? idLote,
    int? insumoId,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final token = await _authService.getToken();
      
      final Map<String, String> queryParams = {};
      if (idLote != null) queryParams['id_lote'] = idLote.toString();
      if (insumoId != null) queryParams['insumo_id'] = insumoId.toString();
      if (fechaInicio != null) queryParams['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) queryParams['fecha_fin'] = fechaFin;

      final uri = Uri.parse('$_baseUrl/alimentacion/').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => AlimentacionModel.fromJson(json)).toList();
      } else {
        print('Error obteniendo alimentación: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Excepción en getAlimentacion: $e');
      return [];
    }
  }

  // CU11: Registrar consumo de alimentación
  Future<bool> postAlimentacion(AlimentacionModel alimentacion) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/alimentacion/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(alimentacion.toJson()),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error registrando alimentación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en postAlimentacion: $e');
      return false;
    }
  }

  // CU11: Registro masivo (bulk) de alimentación
  Future<bool> postAlimentacionBulk(List<AlimentacionModel> registros) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/alimentacion/bulk/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'registros': registros.map((r) => r.toJson()).toList(),
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error en bulk alimentación: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Excepción en postAlimentacionBulk: $e');
      return false;
    }
  }
}

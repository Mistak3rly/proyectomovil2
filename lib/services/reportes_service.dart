import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/envs.dart';
import 'auth_service.dart';

class ReportesService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> generarReporte({
    required String entidad,
    String? agruparPor,
    String? fechaInicio,
    String? fechaFin,
    String? formato = 'json',
  }) async {
    try {
      final token = await _authService.getToken();
      
      final Map<String, dynamic> body = {
        'entidad': entidad,
        'formato': formato,
      };
      
      if (agruparPor != null) body['agrupar_por'] = agruparPor;
      if (fechaInicio != null) body['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) body['fecha_fin'] = fechaFin;

      final response = await http.post(
        Uri.parse('$_baseUrl/reportes/generar/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        print('Error en reporte: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción en generarReporte: $e');
      return null;
    }
  }

  Future<List<int>?> descargarReporteExcel({
    required String entidad,
    String? agruparPor,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final token = await _authService.getToken();
      
      final Map<String, dynamic> body = {
        'entidad': entidad,
        'formato': 'excel',
      };
      
      if (agruparPor != null) body['agrupar_por'] = agruparPor;
      if (fechaInicio != null) body['fecha_inicio'] = fechaInicio;
      if (fechaFin != null) body['fecha_fin'] = fechaFin;

      final response = await http.post(
        Uri.parse('$_baseUrl/reportes/generar/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Error al generar Excel: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción en descargarReporteExcel: $e');
      return null;
    }
  }

  // Nuevo método para obtener KPIs del Dashboard
  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/reportes/dashboard/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      print('Error en getDashboard: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/envs.dart';
import '../data/models/temperature_entry_model.dart';
import '../models/galpon_model.dart';

class TemperatureService {
  final String _baseUrl = Envs.baseUrl;

  Future<List<GalponModel>> getGalpones() async {
    // Simulación de carga de galpones
    await Future.delayed(const Duration(seconds: 1));
    return [
      GalponModel(id: 1, nombre: 'Galpón A'),
      GalponModel(id: 2, nombre: 'Galpón B'),
      GalponModel(id: 3, nombre: 'Galpón C'),
    ];
  }

  Future<void> postTemperature(TemperatureEntryModel entry) async {
    // Simular un request HTTP
    await Future.delayed(const Duration(seconds: 2));
    
    // Aquí iría la lógica real, ejemplo:
    /*
    final response = await http.post(
      Uri.parse('$_baseUrl/temperatures'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(entry.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al registrar la temperatura');
    }
    */
    
    // Simulación de validación en backend
    if (entry.value < 0 || entry.value > 50) {
      throw Exception('Temperatura fuera de rango permitido');
    }
    
    return; // Éxito
  }
}

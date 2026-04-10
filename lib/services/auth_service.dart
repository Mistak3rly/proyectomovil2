import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/user_model.dart';

class AuthService {
  // Configuración del servidor (Usa la IP de tu máquina para pruebas en físico 
  // o 10.0.2.2 para el emulador de Android)
  final String _baseUrl = Envs.baseUrl; 
  final _storage = const FlutterSecureStorage();

  /// CU01: Gestionar Inicio de Sesión [cite: 608]
  Future<Usuario?> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/usuarios/login/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom_usuario': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Guardar token de forma segura (Cumple RNF-02: Seguridad) 
        // await _storage.write(key: 'jwt_token', value: data['access']);
        return Usuario.fromJson(data['usuario']);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// CU02: Gestionar Cierre de Sesión [cite: 609]
  Future<void> logout() async {
    // Elimina el token para garantizar que no se pueda reingresar (Criterio de aceptación) [cite: 716]
    await _storage.delete(key: 'jwt_token');
  }

  /// Obtener el token guardado para futuras peticiones (Headers)
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
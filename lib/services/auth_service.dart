import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/user_model.dart';

class AuthService {
  final String _baseUrl = Envs.baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<Usuario?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom_usuario': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Guardar tokens JWT generados por SimpleJWT
        await _storage.write(key: 'jwt_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);

        // Mapear el usuario desde el JSON devuelto
        return Usuario.fromJson(data['usuario']);
      } else {
        // En caso de error (400, 404), puedes manejarlo aquí o lanzar una excepción
        print('Error en login: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción en login: $e');
      return null;
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      final accessToken = await _storage.read(key: 'jwt_token');

      // Intentar agregar a blacklist el refresh token en el backend
      if (refreshToken != null && accessToken != null) {
        await http.post(
          Uri.parse('$_baseUrl/usuarios/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'refresh': refreshToken}),
        );
      }
    } catch (e) {
      print('Excepción en logout: $e');
    } finally {
      // Siempre borrar los tokens localmente para cerrar sesión en el dispositivo
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
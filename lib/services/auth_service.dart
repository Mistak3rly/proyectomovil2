import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/user_model.dart';

class AuthService {
  final String _baseUrl = Envs.baseUrl;
  final _storage = const FlutterSecureStorage();

  Future<Usuario?> login(String username, String password) async {
    // Simulación de delay para realismo en el mockup
    await Future.delayed(const Duration(seconds: 1));

    if (username == 'juan' && password == '12345') {
      await _storage.write(key: 'jwt_token', value: 'mock_token_juan_12345');
      return Usuario(
        id: 999,
        nomUsuario: 'juan',
        email: 'juan@admin.com',
        tipoUsuario: 'OPERADOR',
        estado: 'ACTIVO',
      );
    }
    return null;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/user_model.dart';

class LoginResult {
  final Usuario? user;
  final String? error;

  const LoginResult._({required this.user, required this.error});
  const LoginResult.success(Usuario user) : this._(user: user, error: null);
  const LoginResult.failure(String message)
    : this._(user: null, error: message);
  bool get isSuccess => user != null;
}

class AuthService {
  final String _baseUrl = Envs.baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthService();

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'] ?? decoded['detail'] ?? decoded['mensaje'];
        if (err is String && err.trim().isNotEmpty) return err;
      }
      return response.body;
    } catch (_) {
      return response.body;
    }
  }

  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nom_usuario': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _storage.write(key: 'jwt_token', value: data['access']);
        await _storage.write(key: 'refresh_token', value: data['refresh']);

        try {
          final usuario = data['usuario'];
          if (usuario is Map<String, dynamic>) {
            final nomUsuario = usuario['nom_usuario'];
            if (nomUsuario is String && nomUsuario.trim().isNotEmpty) {
              await _storage.write(key: 'current_user_name', value: nomUsuario);
            }
            await _storage.write(
              key: 'current_user_json',
              value: jsonEncode(usuario),
            );
          }
        } catch (_) {
          // ignore: empty_catches
        }

        return LoginResult.success(Usuario.fromJson(data['usuario']));
      }

      return LoginResult.failure(_extractErrorMessage(response));
    } catch (e) {
      return LoginResult.failure(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      final accessToken = await _storage.read(key: 'jwt_token');

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
    } catch (_) {
      // ignore: empty_catches
    } finally {
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'jwt_token');
  }

  Future<String?> getCurrentUsername() async {
    return _storage.read(key: 'current_user_name');
  }

  Future<List<String>> getCompanyUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/usuarios/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((u) => (u['nom_usuario'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

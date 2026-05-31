import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/user_model.dart';

class GalponService {
  final String _baseUrl = Envs.baseUrl; 
  Future<Usuario?> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (username == 'juan' && password == '12345') {
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

}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movil_avicola/config/envs.dart';
import 'package:movil_avicola/models/user_model.dart';

class GalponService {
  // Configuración del servidor (Usa la IP de tu máquina para pruebas en físico 
  // o 10.0.2.2 para el emulador de Android)
  final String _baseUrl = Envs.baseUrl; 

  /// CU01: Gestionar Inicio de Sesión (MOCK)
  Future<Usuario?> login(String username, String password) async {
    // Simulación de delay para realismo
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
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movil_avicola/config/envs.dart';

/// Cliente HTTP centralizado basado en Dio.
///
/// Inyecta automáticamente el token JWT almacenado en
/// [FlutterSecureStorage] como cabecera `Authorization: Bearer <token>`
/// en cada solicitud saliente al backend del ERP Avícola.
class ApiClient {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Envs.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ── Interceptor JWT dinámico ────────────────────────────────────────
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Leer el token de acceso encriptado almacenado en el dispositivo.
          final String? accessToken = await _storage.read(key: 'jwt_token');

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Propagar el error para que la capa superior lo maneje.
          return handler.next(error);
        },
      ),
    );
  }
}

import 'package:dio/dio.dart';
import '../core/network/api_client.dart';

/// Servicio exclusivo para el Caso de Uso 18 (CU18):
/// Registrar crecimiento — edad y peso del pollo.
///
/// Despacha los datos recolectados en campo al endpoint
/// `/lotes/control-calidad/` del backend Django REST Framework.
/// El backend calcula automáticamente: edad_dias, peso_estandar,
/// porcentaje_diferencia, estado_desarrollo, empresa_id, usuario_id.
class ControlCalidadService {
  final Dio _dio = ApiClient().dio;

  /// Envía un registro de control de calidad (peso del pollo).
  ///
  /// Parámetros requeridos:
  /// - [idLote]: Clave foránea al lote de aves.
  /// - [pesoRegistrado]: Peso promedio de la muestra en kg.
  /// - [observacion]: Notas del galponero (puede ser vacío).
  /// - [fechaRegistro]: Fecha de la captura en formato ISO (YYYY-MM-DD).
  ///
  /// Retorna la respuesta del servidor como [Response].
  /// Lanza [DioException] en caso de error de red o validación.
  Future<Response> registrarCrecimiento({
    required int idLote,
    required double pesoRegistrado,
    required String observacion,
    required String fechaRegistro,
  }) async {
    final Map<String, dynamic> payload = {
      'id_lote': idLote,
      'peso_registrado': pesoRegistrado,
      'observacion': observacion,
      'fecha_registro': fechaRegistro,
    };

    // POST al endpoint de control de calidad.
    // El interceptor del ApiClient inyecta el Bearer token automáticamente.
    final response = await _dio.post(
      '/lotes/control-calidad/',
      data: payload,
    );

    return response;
  }
}

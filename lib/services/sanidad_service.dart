import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/envs.dart';
import '../models/lote_model.dart';
import '../models/insumo_model.dart';
import '../domain/entities/mortality_record.dart';
import '../domain/entities/tratamiento_model.dart';
import '../domain/entities/vacunacion_model.dart';
import 'auth_service.dart';

class SanidadService {
  final String _baseUrl = Envs.baseUrl;
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kCacheLotes = 'cache_lotes_json';
  static const _kCacheInsumosSanitarios = 'cache_insumos_sanitarios_json';
  static const _kCacheEstadosEnfermedad = 'cache_estados_enfermedad_json';
  static const _kPendingControlSanitario = 'pending_control_sanitario_json';
  static const _kCacheControlesSanitarios = 'cache_controles_sanitarios_json';

  static bool _isLikelyNetworkError(Object e) {
    return e is SocketException;
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'] ?? decoded['detail'] ?? decoded['mensaje'];
        if (err is String && err.trim().isNotEmpty) return err;

        // DRF field errors: { campo: ["msg"] }
        for (final entry in decoded.entries) {
          final v = entry.value;
          if (v is List && v.isNotEmpty && v.first is String) {
            return v.first as String;
          }
        }
      }
      return response.body;
    } catch (_) {
      return response.body;
    }
  }

  Future<void> _writeCache(String key, Object value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  Future<List<dynamic>?> _readCacheList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is List ? decoded : null;
  }

  Future<List<Map<String, dynamic>>> _readPending() async {
    final raw = await _storage.read(key: _kPendingControlSanitario);
    if (raw == null || raw.trim().isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> _writePending(List<Map<String, dynamic>> items) async {
    await _storage.write(
      key: _kPendingControlSanitario,
      value: jsonEncode(items),
    );
  }

  // Obtener lotes activos desde el backend
  Future<List<LoteModel>> getActiveLots({bool allowCache = true}) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/lotes/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        await _writeCache(_kCacheLotes, data);
        return data.map((json) => LoteModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener lotes: ${response.statusCode}');
      }
    } catch (e) {
      if (allowCache && _isLikelyNetworkError(e)) {
        final cached = await _readCacheList(_kCacheLotes);
        if (cached != null) {
          return cached
              .whereType<Map>()
              .map((j) => LoteModel.fromJson(Map<String, dynamic>.from(j)))
              .toList();
        }
      }
      print('Aviso: Error de red o endpoint no listo ($e)');
      rethrow;
    }
  }

  Future<List<InsumoModel>> getSanitarySupplies({
    bool allowCache = true,
  }) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/insumos/catalogo/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final sanitarios = data.where((e) {
          if (e is! Map) return false;
          final tipo = (e['tipo'] ?? '').toString();
          return tipo == 'Vacuna' ||
              tipo == 'Medicamento' ||
              tipo == 'Suministro';
        }).toList();
        await _writeCache(_kCacheInsumosSanitarios, sanitarios);
        return sanitarios
            .whereType<Map>()
            .map((j) => InsumoModel.fromJson(Map<String, dynamic>.from(j)))
            .toList();
      }

      throw Exception('Error al obtener insumos: ${response.statusCode}');
    } catch (e) {
      if (allowCache && _isLikelyNetworkError(e)) {
        final cached = await _readCacheList(_kCacheInsumosSanitarios);
        if (cached != null) {
          return cached
              .whereType<Map>()
              .map((j) => InsumoModel.fromJson(Map<String, dynamic>.from(j)))
              .toList();
        }
      }
      rethrow;
    }
  }

  Future<List<String>> getEstadoEnfermedadSuggestions({
    int? loteId,
    bool allowCache = true,
  }) async {
    try {
      final token = await _authService.getToken();
      final uri = loteId != null
          ? Uri.parse('$_baseUrl/sanitario/aplicaciones/?lote=$loteId')
          : Uri.parse('$_baseUrl/sanitario/aplicaciones/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final set = <String>{};
        for (final item in data) {
          if (item is! Map) continue;
          final v = item['estado_enfermedad'];
          if (v is String && v.trim().isNotEmpty) set.add(v.trim());
        }
        final list = set.toList()..sort();
        await _writeCache(_kCacheEstadosEnfermedad, list);
        return list;
      }

      throw Exception('Error al obtener catálogo: ${response.statusCode}');
    } catch (e) {
      if (allowCache && _isLikelyNetworkError(e)) {
        final raw = await _storage.read(key: _kCacheEstadosEnfermedad);
        if (raw != null && raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            return decoded.whereType<String>().toList();
          }
        }
      }
      return const ['Preventivo', 'Curativo', 'Tratamiento'];
    }
  }

  Future<void> queueControlSanitario(Map<String, dynamic> payload) async {
    final pending = await _readPending();
    pending.add(payload);
    await _writePending(pending);
  }

  Future<int> syncPendingControlSanitario() async {
    final pending = await _readPending();
    if (pending.isEmpty) return 0;

    int synced = 0;
    final remaining = <Map<String, dynamic>>[];
    for (final item in pending) {
      try {
        await createControlSanitario(item);
        synced += 1;
      } catch (_) {
        remaining.add(item);
      }
    }

    await _writePending(remaining);
    return synced;
  }

  Future<List<Map<String, dynamic>>> getControlSanitarioRecords({
    int? loteId,
    bool allowCache = true,
  }) async {
    try {
      final token = await _authService.getToken();
      final uri = loteId != null
          ? Uri.parse('$_baseUrl/sanitario/aplicaciones/?lote=$loteId')
          : Uri.parse('$_baseUrl/sanitario/aplicaciones/');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (loteId == null) {
          await _writeCache(_kCacheControlesSanitarios, data);
        }
        return list;
      }
      throw Exception(
        'Error al obtener registros sanitarios: ${response.statusCode}',
      );
    } catch (e) {
      if (allowCache && _isLikelyNetworkError(e)) {
        final cached = await _readCacheList(_kCacheControlesSanitarios);
        if (cached != null) {
          final list = cached
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          if (loteId != null) {
            return list.where((item) => item['lote'] == loteId).toList();
          }
          return list;
        }
      }
      rethrow;
    }
  }

  Future<void> createControlSanitario(Map<String, dynamic> payload) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/sanitario/aplicaciones/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) return;
    throw Exception(_extractErrorMessage(response));
  }

  Future<void> updateControlSanitario(int id, Map<String, dynamic> payload) async {
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/sanitario/aplicaciones/$id/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(_extractErrorMessage(response));
  }

  Future<void> deleteControlSanitario(int id) async {
    final token = await _authService.getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/sanitario/aplicaciones/$id/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) return;
    throw Exception(_extractErrorMessage(response));
  }

  // CU13: Registrar mortandad
  Future<void> postMortality(MortalityRecord record) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/mortandad/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Error al registrar mortandad: ${response.body}');
    }
  }

  // CU13: Obtener registros de mortandad
  Future<List<MortalityRecord>> getMortalityRecords(int? lotId) async {
    final token = await _authService.getToken();
    final uri = lotId != null
        ? Uri.parse('$_baseUrl/mortandad/?lote=$lotId')
        : Uri.parse('$_baseUrl/mortandad/');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => MortalityRecord.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener mortandad: ${response.statusCode}');
    }
  }

  // CU14: Gráficos de análisis (Usar historial real)
  Future<List<MortalityRecord>> getMockHistoryForAnalysis(int lotId) async {
    try {
      // Ya no usamos mock, traemos el historial real del lote para los gráficos
      return await getMortalityRecords(lotId);
    } catch (e) {
      print('Error al obtener historial para gráficos: $e');
      return [];
    }
  }

  Future<void> postTratamiento(TratamientoModel t) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse(
        '$_baseUrl/sanitario/aplicaciones/',
      ), // Endpoint inferido del backend
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'lote': int.tryParse(t.animalId) ?? 1,
        'tipo_tratamiento': 'Medicamento',
        'insumo': null, // Asumimos null si no hay insumo_id en TratamientoModel
        'dosis': 1.0, // Valores por defecto para cumplir con el serializer
        'unidad_dosis': 'U',
        'responsable': t.veterinario,
        'observacion': '${t.diagnostico}: ${t.medicamento}',
        'fecha_aplicacion': t.fechaInicio.toIso8601String().split('T')[0],
        'estado_enfermedad': t.diagnostico,
      }),
    );

    if (response.statusCode != 201) {
      print('Advertencia: Error al registrar tratamiento ${response.body}');
    }
  }

  Future<void> postVacunacion(VacunacionModel v) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/sanitario/aplicaciones/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'lote': int.tryParse(v.animalId) ?? 1,
        'tipo_tratamiento': 'Vacuna',
        'insumo': null,
        'dosis': 1.0,
        'unidad_dosis': 'Dosis',
        'responsable': v.veterinario,
        'observacion': 'Vacuna: ${v.vacuna}',
        'fecha_aplicacion': v.fechaAplicacion.toIso8601String().split('T')[0],
        'estado_enfermedad': 'Preventivo',
      }),
    );

    if (response.statusCode != 201) {
      print('Advertencia: Error al registrar vacunación ${response.body}');
    }
  }
}

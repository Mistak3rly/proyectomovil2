import 'dart:math';
import '../models/lote_model.dart';
import '../domain/entities/mortality_record.dart';
import '../domain/entities/tratamiento_model.dart';
import '../domain/entities/vacunacion_model.dart';

class SanidadService {
  final List<MortalityRecord> _mockRecords = [];

  Future<List<LoteModel>> getActiveLots() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      LoteModel(id: 1, nombre: 'Lote 1 (Galpón A)', poblacionInicial: 10000, poblacionActual: 9800, diasDeVida: 15),
      LoteModel(id: 2, nombre: 'Lote 2 (Galpón B)', poblacionInicial: 15000, poblacionActual: 14950, diasDeVida: 5),
    ];
  }

  Future<void> postMortality(MortalityRecord record) async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulated validation
    if (record.count <= 0) throw Exception('Cantidad debe ser positiva');
    _mockRecords.add(record);
  }

  Future<List<MortalityRecord>> getMortalityRecords(int? lotId) async {
    await Future.delayed(const Duration(seconds: 1));
    if (lotId == null) return _mockRecords;
    return _mockRecords.where((r) => r.lotId == lotId).toList();
  }
  
  // Para CU14: Gráficos de análisis (Simulación de datos)
  Future<List<MortalityRecord>> getMockHistoryForAnalysis(int lotId) async {
    await Future.delayed(const Duration(seconds: 1));
    final random = Random();
    List<MortalityRecord> history = [];
    final causes = ['Calor', 'Aplastamiento', 'Enfermedad', 'Depredación', 'Otros'];
    
    // Simular los últimos 15 días
    for (int i = 1; i <= 15; i++) {
      int count = random.nextInt(10); // 0 a 9 bajas diarias
      if (count > 0) {
        history.add(MortalityRecord(
          lotId: lotId,
          count: count,
          cause: causes[random.nextInt(causes.length)],
          timestamp: DateTime.now().subtract(Duration(days: 15 - i)),
          userId: 999,
          dayOfLife: i,
        ));
      }
    }
    history.addAll(_mockRecords.where((r) => r.lotId == lotId));
    return history;
  }

  Future<void> postTratamiento(TratamientoModel t) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> postVacunacion(VacunacionModel v) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

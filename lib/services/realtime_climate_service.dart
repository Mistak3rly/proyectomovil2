// CU09: Monitorear temperatura en tiempo real
import 'dart:async';
import 'dart:math';
import '../domain/entities/realtime_climate.dart';
import '../models/galpon_model.dart';

class RealtimeClimateService {
  final Random _random = Random();
  
  // Simulated initial sheds
  final List<GalponModel> _sheds = [
    GalponModel(id: 1, nombre: 'Galpón A'),
    GalponModel(id: 2, nombre: 'Galpón B'),
    GalponModel(id: 3, nombre: 'Galpón C'),
  ];

  Future<List<GalponModel>> getGalpones() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _sheds;
  }

  // Stream that yields new climate data every 2 seconds
  Stream<List<RealtimeClimate>> getClimateStream() async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      
      List<RealtimeClimate> currentClimate = _sheds.map((shed) {
        // Simulate data
        double temp = 15 + _random.nextDouble() * 25; // 15 to 40
        double hum = 40 + _random.nextDouble() * 40;  // 40 to 80
        bool online = _random.nextDouble() > 0.1;     // 10% chance to be offline

        ClimateStatus status;
        if (temp >= 20 && temp <= 26 && hum >= 50 && hum <= 70) {
          status = ClimateStatus.optimal;
        } else if (temp < 18 || temp > 30 || hum < 40 || hum > 80) {
          status = ClimateStatus.critical;
        } else {
          status = ClimateStatus.caution;
        }

        // If offline, values might be 0 or keep last known, we will mock as 0 for simplicity
        if (!online) {
          temp = 0.0;
          hum = 0.0;
        }

        return RealtimeClimate(
          shedId: shed.id,
          shedName: shed.nombre,
          temperature: temp,
          humidity: hum,
          isSensorOnline: online,
          status: status,
        );
      }).toList();

      yield currentClimate;
    }
  }
}

// CU09: Monitorear temperatura en tiempo real
import 'package:equatable/equatable.dart';

enum ClimateStatus { optimal, caution, critical }

class RealtimeClimate extends Equatable {
  final int id;
  final int shedId;
  final String shedName;
  final double temperature;
  final double humidity;
  final bool isSensorOnline;
  final ClimateStatus status;
  final String backendEstado;
  final String mensaje;

  const RealtimeClimate({
    required this.id,
    required this.shedId,
    required this.shedName,
    required this.temperature,
    required this.humidity,
    required this.isSensorOnline,
    required this.status,
    required this.backendEstado,
    required this.mensaje,
  });

  factory RealtimeClimate.fromJson(Map<String, dynamic> json) {
    ClimateStatus mappedStatus;
    switch (json['estado']) {
      case 'FRIO':
      case 'CALOR':
        mappedStatus = ClimateStatus.critical;
        break;
      case 'NORMAL':
        mappedStatus = ClimateStatus.optimal;
        break;
      default:
        mappedStatus = ClimateStatus.caution;
    }

    return RealtimeClimate(
      id: json['id'] ?? 0,
      shedId: json['id_galpon'] ?? 0,
      shedName: json['galpon_nombre'] ?? 'Desconocido',
      temperature: json['temperatura'] != null ? (json['temperatura'] as num).toDouble() : 0.0,
      humidity: 0.0, // El backend actual no envía humedad
      isSensorOnline: true, // Asumimos que si devuelve, está en línea
      status: mappedStatus,
      backendEstado: json['estado'] ?? '',
      mensaje: json['mensaje'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        shedId,
        shedName,
        temperature,
        humidity,
        isSensorOnline,
        status,
        backendEstado,
        mensaje,
      ];
}

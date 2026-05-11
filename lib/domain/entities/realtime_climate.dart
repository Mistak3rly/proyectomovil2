// CU09: Monitorear temperatura en tiempo real
import 'package:equatable/equatable.dart';

enum ClimateStatus { optimal, caution, critical }

class RealtimeClimate extends Equatable {
  final int shedId;
  final String shedName;
  final double temperature;
  final double humidity;
  final bool isSensorOnline;
  final ClimateStatus status;

  const RealtimeClimate({
    required this.shedId,
    required this.shedName,
    required this.temperature,
    required this.humidity,
    required this.isSensorOnline,
    required this.status,
  });

  @override
  List<Object?> get props => [
        shedId,
        shedName,
        temperature,
        humidity,
        isSensorOnline,
        status,
      ];
}

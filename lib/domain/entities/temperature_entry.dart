import 'package:equatable/equatable.dart';

class TemperatureEntry extends Equatable {
  final int shedId;
  final double value;
  final DateTime timestamp;

  const TemperatureEntry({
    required this.shedId,
    required this.value,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [shedId, value, timestamp];
}

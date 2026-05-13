import '../../domain/entities/temperature_entry.dart';

class TemperatureEntryModel extends TemperatureEntry {
  const TemperatureEntryModel({
    required super.shedId,
    required super.value,
    required super.timestamp,
  });

  factory TemperatureEntryModel.fromJson(Map<String, dynamic> json) {
    return TemperatureEntryModel(
      shedId: json['id_galpon'],
      value: (json['temperatura'] as num).toDouble(),
      timestamp: DateTime.parse(json['fecha_hora']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_galpon': shedId,
      'temperatura': value,
      'fecha_hora': timestamp.toIso8601String(),
    };
  }
}

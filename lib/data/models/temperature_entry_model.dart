import '../../domain/entities/temperature_entry.dart';

class TemperatureEntryModel extends TemperatureEntry {
  const TemperatureEntryModel({
    required super.shedId,
    required super.value,
    required super.timestamp,
  });

  factory TemperatureEntryModel.fromJson(Map<String, dynamic> json) {
    return TemperatureEntryModel(
      shedId: json['shedId'],
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shedId': shedId,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

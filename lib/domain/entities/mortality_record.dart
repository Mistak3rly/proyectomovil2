import 'package:equatable/equatable.dart';

class MortalityRecord extends Equatable {
  final int? id;
  final int lotId;
  final int count;
  final String cause;
  final DateTime timestamp;
  final String? observacion;

  const MortalityRecord({
    this.id,
    required this.lotId,
    required this.count,
    required this.cause,
    required this.timestamp,
    this.observacion,
  });

  factory MortalityRecord.fromJson(Map<String, dynamic> json) {
    return MortalityRecord(
      id: json['id_muerte'],
      lotId: json['lote'],
      count: json['cantidad'],
      cause: json['causa'] ?? 'No especificada',
      timestamp: json['fecha_hora'] != null ? DateTime.parse(json['fecha_hora']) : DateTime.now(),
      observacion: json['observacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lote': lotId,
      'cantidad': count,
      'causa': cause,
      'fecha_hora': timestamp.toIso8601String(),
      if (observacion != null) 'observacion': observacion,
    };
  }

  @override
  List<Object?> get props => [id, lotId, count, cause, timestamp, observacion];
}

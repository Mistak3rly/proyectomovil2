import 'package:equatable/equatable.dart';

class MortalityRecord extends Equatable {
  final int? id;
  final int lotId;
  final int count;
  final String cause;
  final String? observations;
  final DateTime timestamp;
  final int userId;
  final int dayOfLife; // Día del ciclo de vida en el que ocurrió

  const MortalityRecord({
    this.id,
    required this.lotId,
    required this.count,
    required this.cause,
    this.observations,
    required this.timestamp,
    required this.userId,
    required this.dayOfLife,
  });

  @override
  List<Object?> get props => [id, lotId, count, cause, observations, timestamp, userId, dayOfLife];
}

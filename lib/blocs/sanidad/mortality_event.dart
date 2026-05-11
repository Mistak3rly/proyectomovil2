import 'package:equatable/equatable.dart';

abstract class MortalityEvent extends Equatable {
  const MortalityEvent();
  @override
  List<Object?> get props => [];
}

class LoadActiveLots extends MortalityEvent {}

class SubmitMortality extends MortalityEvent {
  final int lotId;
  final int count;
  final String cause;
  final String? observations;
  final int currentDayOfLife;

  const SubmitMortality({
    required this.lotId,
    required this.count,
    required this.cause,
    this.observations,
    required this.currentDayOfLife,
  });

  @override
  List<Object?> get props => [lotId, count, cause, observations, currentDayOfLife];
}

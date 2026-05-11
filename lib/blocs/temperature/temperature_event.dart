part of 'temperature_bloc.dart';

abstract class TemperatureEvent extends Equatable {
  const TemperatureEvent();

  @override
  List<Object?> get props => [];
}

class LoadSheds extends TemperatureEvent {}

class SubmitTemperature extends TemperatureEvent {
  final int shedId;
  final double value;

  const SubmitTemperature({
    required this.shedId,
    required this.value,
  });

  @override
  List<Object?> get props => [shedId, value];
}

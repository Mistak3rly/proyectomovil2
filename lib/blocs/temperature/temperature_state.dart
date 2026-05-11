part of 'temperature_bloc.dart';

abstract class TemperatureState extends Equatable {
  const TemperatureState();
  
  @override
  List<Object?> get props => [];
}

class TemperatureInitial extends TemperatureState {
  final List<GalponModel> sheds;
  const TemperatureInitial({this.sheds = const []});

  @override
  List<Object?> get props => [sheds];
}

class TemperatureLoading extends TemperatureState {}

class TemperatureSuccess extends TemperatureState {
  final String message;
  
  const TemperatureSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class TemperatureError extends TemperatureState {
  final String message;

  const TemperatureError(this.message);

  @override
  List<Object?> get props => [message];
}

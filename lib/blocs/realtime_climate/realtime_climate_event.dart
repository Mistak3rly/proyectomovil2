// CU09: Monitorear temperatura en tiempo real
part of 'realtime_climate_bloc.dart';

abstract class RealtimeClimateEvent extends Equatable {
  const RealtimeClimateEvent();

  @override
  List<Object?> get props => [];
}

class StartRealtimeMonitoring extends RealtimeClimateEvent {}

class StopRealtimeMonitoring extends RealtimeClimateEvent {}

class UpdateClimateData extends RealtimeClimateEvent {
  final List<RealtimeClimate> climates;

  const UpdateClimateData(this.climates);

  @override
  List<Object?> get props => [climates];
}

class FilterByShed extends RealtimeClimateEvent {
  final int? shedId;

  const FilterByShed(this.shedId);

  @override
  List<Object?> get props => [shedId];
}

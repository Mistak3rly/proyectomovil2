// CU09: Monitorear temperatura en tiempo real
part of 'realtime_climate_bloc.dart';

abstract class RealtimeClimateState extends Equatable {
  const RealtimeClimateState();
  
  @override
  List<Object?> get props => [];
}

class RealtimeClimateInitial extends RealtimeClimateState {}

class RealtimeClimateLoading extends RealtimeClimateState {}

class RealtimeClimateLoaded extends RealtimeClimateState {
  final List<RealtimeClimate> allClimates;
  final List<RealtimeClimate> filteredClimates;
  final int? selectedShedId;
  final List<GalponModel> sheds;

  const RealtimeClimateLoaded({
    required this.allClimates,
    required this.filteredClimates,
    required this.sheds,
    this.selectedShedId,
  });

  RealtimeClimateLoaded copyWith({
    List<RealtimeClimate>? allClimates,
    List<RealtimeClimate>? filteredClimates,
    List<GalponModel>? sheds,
    int? selectedShedId,
    bool clearShedFilter = false,
  }) {
    return RealtimeClimateLoaded(
      allClimates: allClimates ?? this.allClimates,
      filteredClimates: filteredClimates ?? this.filteredClimates,
      sheds: sheds ?? this.sheds,
      selectedShedId: clearShedFilter ? null : (selectedShedId ?? this.selectedShedId),
    );
  }

  @override
  List<Object?> get props => [allClimates, filteredClimates, sheds, selectedShedId];
}

class RealtimeClimateError extends RealtimeClimateState {
  final String message;

  const RealtimeClimateError(this.message);

  @override
  List<Object?> get props => [message];
}

// CU09: Monitorear temperatura en tiempo real
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/realtime_climate.dart';
import '../../services/realtime_climate_service.dart';
import '../../models/galpon_model.dart';

part 'realtime_climate_event.dart';
part 'realtime_climate_state.dart';

class RealtimeClimateBloc extends Bloc<RealtimeClimateEvent, RealtimeClimateState> {
  final RealtimeClimateService service;
  StreamSubscription<List<RealtimeClimate>>? _climateSubscription;

  RealtimeClimateBloc({required this.service}) : super(RealtimeClimateInitial()) {
    on<StartRealtimeMonitoring>(_onStartRealtimeMonitoring);
    on<StopRealtimeMonitoring>(_onStopRealtimeMonitoring);
    on<UpdateClimateData>(_onUpdateClimateData);
    on<FilterByShed>(_onFilterByShed);
  }

  Future<void> _onStartRealtimeMonitoring(StartRealtimeMonitoring event, Emitter<RealtimeClimateState> emit) async {
    emit(RealtimeClimateLoading());
    try {
      final sheds = await service.getGalpones();
      
      _climateSubscription?.cancel();
      _climateSubscription = service.getClimateStream().listen((climates) {
        add(UpdateClimateData(climates));
      });

      emit(RealtimeClimateLoaded(
        allClimates: const [],
        filteredClimates: const [],
        sheds: sheds,
      ));
    } catch (e) {
      emit(RealtimeClimateError('Error iniciando monitoreo: ${e.toString()}'));
    }
  }

  void _onUpdateClimateData(UpdateClimateData event, Emitter<RealtimeClimateState> emit) {
    if (state is RealtimeClimateLoaded) {
      final currentState = state as RealtimeClimateLoaded;
      
      List<RealtimeClimate> filtered = event.climates;
      if (currentState.selectedShedId != null) {
        filtered = event.climates.where((c) => c.shedId == currentState.selectedShedId).toList();
      }

      emit(currentState.copyWith(
        allClimates: event.climates,
        filteredClimates: filtered,
      ));
    }
  }

  void _onFilterByShed(FilterByShed event, Emitter<RealtimeClimateState> emit) {
    if (state is RealtimeClimateLoaded) {
      final currentState = state as RealtimeClimateLoaded;
      
      List<RealtimeClimate> filtered = currentState.allClimates;
      if (event.shedId != null) {
        filtered = currentState.allClimates.where((c) => c.shedId == event.shedId).toList();
      }

      emit(currentState.copyWith(
        filteredClimates: filtered,
        selectedShedId: event.shedId,
        clearShedFilter: event.shedId == null,
      ));
    }
  }

  void _onStopRealtimeMonitoring(StopRealtimeMonitoring event, Emitter<RealtimeClimateState> emit) {
    _climateSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _climateSubscription?.cancel();
    return super.close();
  }
}

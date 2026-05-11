import 'package:bloc/bloc.dart';
import '../../services/sanidad_service.dart';
import '../../domain/entities/mortality_record.dart';
import 'mortality_event.dart';
import 'mortality_state.dart';

class MortalityBloc extends Bloc<MortalityEvent, MortalityState> {
  final SanidadService service;

  MortalityBloc({required this.service}) : super(MortalityInitial()) {
    on<LoadActiveLots>(_onLoadActiveLots);
    on<SubmitMortality>(_onSubmitMortality);
  }

  Future<void> _onLoadActiveLots(LoadActiveLots event, Emitter<MortalityState> emit) async {
    emit(MortalityLoading());
    try {
      final lots = await service.getActiveLots();
      emit(LotsLoaded(lots));
    } catch (e) {
      emit(MortalityError(e.toString()));
    }
  }

  Future<void> _onSubmitMortality(SubmitMortality event, Emitter<MortalityState> emit) async {
    emit(MortalityLoading());
    try {
      final record = MortalityRecord(
        lotId: event.lotId,
        count: event.count,
        cause: event.cause,
        observations: event.observations,
        timestamp: DateTime.now(),
        userId: 999, // Simulado
        dayOfLife: event.currentDayOfLife,
      );
      
      await service.postMortality(record);
      emit(const MortalitySuccess('Registro de bajas guardado correctamente'));
    } catch (e) {
      emit(MortalityError('Error: ${e.toString()}'));
    }
  }
}

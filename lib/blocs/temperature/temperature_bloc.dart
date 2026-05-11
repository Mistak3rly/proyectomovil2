import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/galpon_model.dart';
import '../../services/temperature_service.dart';
import '../../data/models/temperature_entry_model.dart';

part 'temperature_event.dart';
part 'temperature_state.dart';

class TemperatureBloc extends Bloc<TemperatureEvent, TemperatureState> {
  final TemperatureService temperatureService;

  TemperatureBloc({required this.temperatureService}) : super(const TemperatureInitial()) {
    on<LoadSheds>(_onLoadSheds);
    on<SubmitTemperature>(_onSubmitTemperature);
  }

  Future<void> _onLoadSheds(LoadSheds event, Emitter<TemperatureState> emit) async {
    emit(TemperatureLoading());
    try {
      final sheds = await temperatureService.getGalpones();
      emit(TemperatureInitial(sheds: sheds));
    } catch (e) {
      emit(TemperatureError('Error al cargar galpones: ${e.toString()}'));
    }
  }

  Future<void> _onSubmitTemperature(SubmitTemperature event, Emitter<TemperatureState> emit) async {
    emit(TemperatureLoading());
    try {
      final entry = TemperatureEntryModel(
        shedId: event.shedId,
        value: event.value,
        timestamp: DateTime.now(), // Timestamp automático
      );
      
      await temperatureService.postTemperature(entry);
      
      emit(const TemperatureSuccess('Temperatura registrada con éxito'));
    } catch (e) {
      emit(TemperatureError('Error al registrar: ${e.toString()}'));
    }
  }
}

import 'package:bloc/bloc.dart';
import '../../services/sanidad_service.dart';
import 'mortality_analysis_state.dart';
import '../../models/lote_model.dart';

class MortalityAnalysisBloc extends Bloc<MortalityAnalysisEvent, MortalityAnalysisState> {
  final SanidadService service;

  MortalityAnalysisBloc({required this.service}) : super(MortalityAnalysisInitial()) {
    on<LoadAnalysisData>(_onLoadAnalysisData);
    on<SelectLotForAnalysis>(_onSelectLotForAnalysis);
  }

  Future<void> _onLoadAnalysisData(LoadAnalysisData event, Emitter<MortalityAnalysisState> emit) async {
    emit(MortalityAnalysisLoading());
    try {
      final lots = await service.getActiveLots();
      if (lots.isNotEmpty) {
        add(SelectLotForAnalysis(lots.first));
      } else {
        emit(const MortalityAnalysisLoaded(
          lots: [],
          records: [],
          mortalityRate: 0.0,
          totalDeaths: 0,
        ));
      }
    } catch (e) {
      emit(MortalityAnalysisError('Error: ${e.toString()}'));
    }
  }

  Future<void> _onSelectLotForAnalysis(SelectLotForAnalysis event, Emitter<MortalityAnalysisState> emit) async {
    emit(MortalityAnalysisLoading());
    try {
      final lots = await service.getActiveLots();
      final records = await service.getMockHistoryForAnalysis(event.lot.id);
      
      int totalDeaths = records.fold(0, (sum, item) => sum + item.count);
      double rate = 0.0;
      if (event.lot.poblacionInicial > 0) {
        rate = (totalDeaths / event.lot.poblacionInicial) * 100;
      }

      emit(MortalityAnalysisLoaded(
        lots: lots,
        selectedLot: event.lot,
        records: records,
        mortalityRate: rate,
        totalDeaths: totalDeaths,
      ));
    } catch (e) {
      emit(MortalityAnalysisError('Error: ${e.toString()}'));
    }
  }
}

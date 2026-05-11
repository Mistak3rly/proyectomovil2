import 'package:equatable/equatable.dart';
import '../../models/lote_model.dart';
import '../../domain/entities/mortality_record.dart';

abstract class MortalityAnalysisState extends Equatable {
  const MortalityAnalysisState();
  @override
  List<Object?> get props => [];
}

class MortalityAnalysisInitial extends MortalityAnalysisState {}

class MortalityAnalysisLoading extends MortalityAnalysisState {}

class MortalityAnalysisLoaded extends MortalityAnalysisState {
  final List<LoteModel> lots;
  final LoteModel? selectedLot;
  final List<MortalityRecord> records;
  final double mortalityRate;
  final int totalDeaths;

  const MortalityAnalysisLoaded({
    required this.lots,
    this.selectedLot,
    required this.records,
    required this.mortalityRate,
    required this.totalDeaths,
  });

  @override
  List<Object?> get props => [lots, selectedLot, records, mortalityRate, totalDeaths];
}

class MortalityAnalysisError extends MortalityAnalysisState {
  final String message;
  const MortalityAnalysisError(this.message);
  @override
  List<Object?> get props => [message];
}

// Events
abstract class MortalityAnalysisEvent extends Equatable {
  const MortalityAnalysisEvent();
  @override
  List<Object?> get props => [];
}

class LoadAnalysisData extends MortalityAnalysisEvent {}

class SelectLotForAnalysis extends MortalityAnalysisEvent {
  final LoteModel lot;
  const SelectLotForAnalysis(this.lot);
  @override
  List<Object?> get props => [lot];
}

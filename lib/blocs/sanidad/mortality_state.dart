import 'package:equatable/equatable.dart';
import '../../models/lote_model.dart';
import '../../domain/entities/mortality_record.dart';

abstract class MortalityState extends Equatable {
  const MortalityState();
  @override
  List<Object?> get props => [];
}

class MortalityInitial extends MortalityState {}

class MortalityLoading extends MortalityState {}

class LotsLoaded extends MortalityState {
  final List<LoteModel> lots;
  const LotsLoaded(this.lots);
  @override
  List<Object?> get props => [lots];
}

class MortalitySuccess extends MortalityState {
  final String message;
  const MortalitySuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class MortalityError extends MortalityState {
  final String message;
  const MortalityError(this.message);
  @override
  List<Object?> get props => [message];
}

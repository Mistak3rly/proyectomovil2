import 'package:equatable/equatable.dart';

class LoteModel extends Equatable {
  final int id;
  final String nombre;
  final int poblacionInicial;
  final int poblacionActual;
  final int diasDeVida;

  const LoteModel({
    required this.id,
    required this.nombre,
    required this.poblacionInicial,
    required this.poblacionActual,
    required this.diasDeVida,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    return LoteModel(
      id: json['id'],
      nombre: json['nombre'],
      poblacionInicial: json['poblacionInicial'],
      poblacionActual: json['poblacionActual'],
      diasDeVida: json['diasDeVida'],
    );
  }

  @override
  List<Object?> get props => [id, nombre, poblacionInicial, poblacionActual, diasDeVida];
}

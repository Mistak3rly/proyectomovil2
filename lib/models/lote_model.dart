import 'package:equatable/equatable.dart';

class LoteModel extends Equatable {
  final int id; // id_lote en DB
  final int idGalpon;
  final String razaTipo;
  final String nombre; // Lo calcularemos o usaremos uno default si no viene
  final int poblacionInicial; // cantidad_inicial
  final int poblacionActual; // cantidad_actual
  final int diasDeVida; // Calculado de fecha_ingreso
  final DateTime fechaIngreso;
  final String? estado;

  const LoteModel({
    required this.id,
    required this.idGalpon,
    required this.razaTipo,
    required this.nombre,
    required this.poblacionInicial,
    required this.poblacionActual,
    required this.diasDeVida,
    required this.fechaIngreso,
    this.estado,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    final fechaIngreso = json['fecha_ingreso'] != null ? DateTime.parse(json['fecha_ingreso']) : DateTime.now();
    final dias = DateTime.now().difference(fechaIngreso).inDays;

    return LoteModel(
      id: json['id_lote'],
      idGalpon: json['id_galpon'] ?? 0,
      razaTipo: json['raza_tipo'] ?? 'Desconocida',
      nombre: 'Lote ${json['id_lote']}', // Nombre corto visible en dropdowns
      poblacionInicial: json['cantidad_inicial'] ?? 0,
      poblacionActual: json['cantidad_actual'] ?? 0,
      diasDeVida: dias >= 0 ? dias : 0,
      fechaIngreso: fechaIngreso,
      estado: json['estado'],
    );
  }

  @override
  List<Object?> get props => [id, idGalpon, razaTipo, nombre, poblacionInicial, poblacionActual, diasDeVida, fechaIngreso, estado];
}

import 'package:equatable/equatable.dart';

class InsumoModel extends Equatable {
  final int id;
  final String nombre;
  final String tipo;
  final String unidadMedida;
  final double stockActual;
  final double stockMinimo;

  const InsumoModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.unidadMedida,
    required this.stockActual,
    required this.stockMinimo,
  });

  factory InsumoModel.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return InsumoModel(
      id: json['id_insumo'] ?? json['id'] ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      tipo: (json['tipo'] ?? '').toString(),
      unidadMedida: (json['unidad_medida'] ?? '').toString(),
      stockActual: toDouble(json['stock_actual']),
      stockMinimo: toDouble(json['stock_minimo']),
    );
  }

  bool get bajoStock => stockActual <= stockMinimo;

  @override
  List<Object?> get props => [
    id,
    nombre,
    tipo,
    unidadMedida,
    stockActual,
    stockMinimo,
  ];
}

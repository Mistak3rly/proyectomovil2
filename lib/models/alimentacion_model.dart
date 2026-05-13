class AlimentacionModel {
  final int? idAlimentacion;
  final int idLote;
  final int? insumoId;
  final String? insumoNombre;
  final DateTime fecha;
  final double cantidadKg;
  final String tipoAlimento;
  final String? observacion;

  AlimentacionModel({
    this.idAlimentacion,
    required this.idLote,
    this.insumoId,
    this.insumoNombre,
    required this.fecha,
    required this.cantidadKg,
    required this.tipoAlimento,
    this.observacion,
  });

  factory AlimentacionModel.fromJson(Map<String, dynamic> json) {
    return AlimentacionModel(
      idAlimentacion: json['id_alimentacion'],
      idLote: json['id_lote'],
      insumoId: json['insumo_id'],
      insumoNombre: json['insumo_nombre'],
      fecha: DateTime.parse(json['fecha']),
      cantidadKg: (json['cantidad_kg'] as num).toDouble(),
      tipoAlimento: json['tipo_alimento'],
      observacion: json['observacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_lote': idLote,
      if (insumoId != null) 'insumo_id': insumoId,
      'fecha': fecha.toIso8601String().split('T')[0],
      'cantidad_kg': cantidadKg,
      'tipo_alimento': tipoAlimento,
      if (observacion != null) 'observacion': observacion,
    };
  }
}

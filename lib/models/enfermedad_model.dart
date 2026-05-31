class EnfermedadModel {
  final int? id;
  final int lote;
  final String enfermedadSintoma;
  final int? cantidadAvesAfectadas;
  final double? porcentajeAfectacion;
  final String estadoEnfermedad;
  final String? observacion;
  final DateTime? fechaRegistro;

  EnfermedadModel({
    this.id,
    required this.lote,
    required this.enfermedadSintoma,
    this.cantidadAvesAfectadas,
    this.porcentajeAfectacion,
    this.estadoEnfermedad = 'activo',
    this.observacion,
    this.fechaRegistro,
  });

  factory EnfermedadModel.fromJson(Map<String, dynamic> json) {
    return EnfermedadModel(
      id: json['id'],
      lote: json['lote'],
      enfermedadSintoma: json['enfermedad_sintoma'] ?? '',
      cantidadAvesAfectadas: json['cantidad_aves_afectadas'],
      porcentajeAfectacion: json['porcentaje_afectacion'] != null
          ? double.tryParse(json['porcentaje_afectacion'].toString())
          : null,
      estadoEnfermedad: json['estado_enfermedad'] ?? 'activo',
      observacion: json['observacion'],
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.tryParse(json['fecha_registro'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lote': lote,
      'enfermedad_sintoma': enfermedadSintoma,
      if (cantidadAvesAfectadas != null)
        'cantidad_aves_afectadas': cantidadAvesAfectadas,
      if (porcentajeAfectacion != null)
        'porcentaje_afectacion': porcentajeAfectacion,
      'estado_enfermedad': estadoEnfermedad,
      if (observacion != null && observacion!.isNotEmpty)
        'observacion': observacion,
    };
  }
}

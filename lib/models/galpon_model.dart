import 'package:equatable/equatable.dart';

class GalponModel extends Equatable {
  final int id;
  final String nombre;
  final int? capacidad;
  final String? descripcion;
  final String? estado;

  const GalponModel({
    required this.id,
    required this.nombre,
    this.capacidad,
    this.descripcion,
    this.estado,
  });

  factory GalponModel.fromJson(Map<String, dynamic> json) {
    return GalponModel(
      id: json['id'],
      nombre: json['nombre'],
      capacidad: json['capacidad'],
      descripcion: json['descripcion'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      if (capacidad != null) 'capacidad': capacidad,
      if (descripcion != null) 'descripcion': descripcion,
      if (estado != null) 'estado': estado,
    };
  }

  @override
  List<Object?> get props => [id, nombre, capacidad, descripcion, estado];
}

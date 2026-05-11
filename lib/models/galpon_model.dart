import 'package:equatable/equatable.dart';

class GalponModel extends Equatable {
  final int id;
  final String nombre;

  const GalponModel({
    required this.id,
    required this.nombre,
  });

  factory GalponModel.fromJson(Map<String, dynamic> json) {
    return GalponModel(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  @override
  List<Object?> get props => [id, nombre];
}

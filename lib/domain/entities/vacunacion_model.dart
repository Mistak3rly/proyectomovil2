class VacunacionModel {
  final String? id;
  final String animalId;
  final String vacuna;
  final String dosis;
  final DateTime fechaAplicacion;
  final DateTime? proximaDosis;
  final String veterinario;

  VacunacionModel({
    this.id,
    required this.animalId,
    required this.vacuna,
    required this.dosis,
    required this.fechaAplicacion,
    this.proximaDosis,
    required this.veterinario,
  });
}

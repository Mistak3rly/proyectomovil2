class TratamientoModel {
  final String? id;
  final String animalId; // O loteId según convenga, el prompt pide animalId
  final String diagnostico;
  final String medicamento;
  final String dosis;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String veterinario;

  TratamientoModel({
    this.id,
    required this.animalId,
    required this.diagnostico,
    required this.medicamento,
    required this.dosis,
    required this.fechaInicio,
    required this.fechaFin,
    required this.veterinario,
  });
}

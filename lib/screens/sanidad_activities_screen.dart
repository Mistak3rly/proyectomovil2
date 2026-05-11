import 'package:flutter/material.dart';

class SanidadActivitiesScreen extends StatefulWidget {
  const SanidadActivitiesScreen({super.key});

  @override
  State<SanidadActivitiesScreen> createState() => _SanidadActivitiesScreenState();
}

class _SanidadActivitiesScreenState extends State<SanidadActivitiesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animalIdController = TextEditingController();
  final _dosisController = TextEditingController();
  final _vetController = TextEditingController();
  
  String? _selectedTipo;
  DateTime? _fechaAplicacion;
  
  final List<String> _tiposMedicamento = ['Vacuna A', 'Vacuna B', 'Antibiótico C', 'Vitaminas D'];

  @override
  void dispose() {
    _animalIdController.dispose();
    _dosisController.dispose();
    _vetController.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() {
        _fechaAplicacion = date;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _fechaAplicacion != null && _selectedTipo != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Actividad guardada correctamente'), backgroundColor: Colors.green));
      _animalIdController.clear();
      _dosisController.clear();
      _vetController.clear();
      setState(() {
        _fechaAplicacion = null;
        _selectedTipo = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos obligatorios'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Actividades Sanitarias')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo Registro (Tratamiento/Vacunación)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _animalIdController,
                    decoration: const InputDecoration(labelText: 'ID del Animal/Lote', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo de Medicamento/Vacuna', border: OutlineInputBorder()),
                    value: _selectedTipo,
                    items: _tiposMedicamento.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedTipo = val),
                    validator: (value) => value == null ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dosisController,
                    decoration: const InputDecoration(labelText: 'Dosis (ej. 5ml)', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Fecha de Aplicación', border: OutlineInputBorder()),
                      child: Text(_fechaAplicacion == null ? 'Seleccionar fecha' : '${_fechaAplicacion!.day}/${_fechaAplicacion!.month}/${_fechaAplicacion!.year}'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vetController,
                    decoration: const InputDecoration(labelText: 'Veterinario Responsable', border: OutlineInputBorder()),
                    validator: (value) => value!.isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Registrar Actividad'),
                  )
                ],
              ),
            ),
            const Divider(height: 40, thickness: 2),
            const Text('Registros Anteriores', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.vaccines, color: Colors.blue),
                    title: Text('Animal #${100 + index} - ${_tiposMedicamento[index]}'),
                    subtitle: const Text('Fecha: 10/05/2026 | Vet: Dr. Lopez'),
                    trailing: const Text('Completado', style: TextStyle(color: Colors.green)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

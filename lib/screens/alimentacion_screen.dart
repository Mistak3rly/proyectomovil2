import 'package:flutter/material.dart';
import '../../services/alimentacion_service.dart';
import '../../services/sanidad_service.dart';
import '../../models/alimentacion_model.dart';
import '../../models/lote_model.dart';

class AlimentacionScreen extends StatefulWidget {
  const AlimentacionScreen({super.key});

  @override
  State<AlimentacionScreen> createState() => _AlimentacionScreenState();
}

class _AlimentacionScreenState extends State<AlimentacionScreen> {
  final AlimentacionService _alimentacionService = AlimentacionService();
  final SanidadService _sanidadService = SanidadService();

  List<AlimentacionModel> _historial = [];
  List<LoteModel> _lotes = [];
  bool _isLoading = true;

  LoteModel? _selectedLote;
  final _cantidadController = TextEditingController();
  final _tipoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final lotes = await _sanidadService.getActiveLots();
      final historial = await _alimentacionService.getAlimentacion();
      
      if (mounted) {
        setState(() {
          _lotes = lotes;
          _historial = historial;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading alimentacion: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAlimentacion() async {
    if (_selectedLote == null || _cantidadController.text.isEmpty || _tipoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete todos los campos')));
      return;
    }

    final double? cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cantidad inválida')));
      return;
    }

    final registro = AlimentacionModel(
      idLote: _selectedLote!.id,
      fecha: DateTime.now(),
      cantidadKg: cantidad,
      tipoAlimento: _tipoController.text,
    );

    final success = await _alimentacionService.postAlimentacion(registro);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro guardado')));
      _cantidadController.clear();
      _tipoController.clear();
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Registro de Alimentación', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<LoteModel>(
                    decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder()),
                    value: _selectedLote,
                    items: _lotes.map((l) => DropdownMenuItem(value: l, child: Text(l.nombre))).toList(),
                    onChanged: (val) => setState(() => _selectedLote = val),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _tipoController,
                    decoration: const InputDecoration(labelText: 'Tipo de Alimento', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad (Kg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitAlimentacion,
                    child: const Text('Registrar Consumo'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text('Historial Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_historial.isEmpty) const Text('No hay registros de alimentación.'),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _historial.length,
            itemBuilder: (context, index) {
              final item = _historial[index];
              return ListTile(
                leading: const Icon(Icons.fastfood, color: Colors.green),
                title: Text('${item.cantidadKg} Kg de ${item.tipoAlimento}'),
                subtitle: Text('Lote ID: ${item.idLote} - ${item.fecha.toLocal().toString().split(' ')[0]}'),
              );
            },
          ),
        ],
      ),
    );
  }
}

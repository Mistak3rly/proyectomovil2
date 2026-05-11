import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../blocs/sanidad/mortality_bloc.dart';
import '../../blocs/sanidad/mortality_event.dart';
import '../../blocs/sanidad/mortality_state.dart';
import '../../services/sanidad_service.dart';
import '../../models/lote_model.dart';

class RegisterMortalityScreen extends StatefulWidget {
  const RegisterMortalityScreen({super.key});

  @override
  State<RegisterMortalityScreen> createState() => _RegisterMortalityScreenState();
}

class _RegisterMortalityScreenState extends State<RegisterMortalityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _obsController = TextEditingController();
  LoteModel? _selectedLot;
  String? _selectedCause;

  final List<String> _causes = ['Calor', 'Aplastamiento', 'Enfermedad', 'Depredación', 'Otros'];

  @override
  void dispose() {
    _countController.dispose();
    _obsController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_selectedLot == null || _selectedCause == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor complete todos los campos obligatorios'), backgroundColor: Colors.red),
        );
        return;
      }
      
      final int count = int.parse(_countController.text);
      
      context.read<MortalityBloc>().add(
        SubmitMortality(
          lotId: _selectedLot!.id,
          count: count,
          cause: _selectedCause!,
          observations: _obsController.text.isNotEmpty ? _obsController.text : null,
          currentDayOfLife: _selectedLot!.diasDeVida,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final SanidadService service = GetIt.instance.isRegistered<SanidadService>() 
        ? GetIt.instance<SanidadService>() 
        : SanidadService();

    return BlocProvider(
      create: (context) => MortalityBloc(service: service)..add(LoadActiveLots()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar Mortandad')),
        body: BlocConsumer<MortalityBloc, MortalityState>(
          listener: (context, state) {
            if (state is MortalitySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
              _countController.clear();
              _obsController.clear();
              setState(() {
                _selectedLot = null;
                _selectedCause = null;
              });
              context.read<MortalityBloc>().add(LoadActiveLots());
            } else if (state is MortalityError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
              context.read<MortalityBloc>().add(LoadActiveLots());
            }
          },
          builder: (context, state) {
            if (state is MortalityLoading || state is MortalityInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            List<LoteModel> lots = [];
            if (state is LotsLoaded) {
              lots = state.lots;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<LoteModel>(
                      decoration: const InputDecoration(labelText: 'Lote Activo', border: OutlineInputBorder()),
                      value: _selectedLot,
                      items: lots.map((lot) => DropdownMenuItem(value: lot, child: Text('${lot.nombre} - Pob: ${lot.poblacionActual}'))).toList(),
                      onChanged: (value) => setState(() => _selectedLot = value),
                      validator: (value) => value == null ? 'Seleccione un lote' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Cantidad de Bajas', border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ingrese la cantidad';
                        final count = int.tryParse(value);
                        if (count == null || count <= 0) return 'Debe ser un número positivo';
                        if (_selectedLot != null && count > _selectedLot!.poblacionActual) {
                          return 'No puede superar la población actual (${_selectedLot!.poblacionActual})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Causa de Muerte', border: OutlineInputBorder()),
                      value: _selectedCause,
                      items: _causes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (value) => setState(() => _selectedCause = value),
                      validator: (value) => value == null ? 'Seleccione una causa' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _obsController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Observaciones (Opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () => _submitForm(context),
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Registro', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

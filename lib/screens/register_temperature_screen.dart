import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../blocs/temperature/temperature_bloc.dart';
import '../services/temperature_service.dart';
import '../models/galpon_model.dart';

class RegisterTemperatureScreen extends StatefulWidget {
  const RegisterTemperatureScreen({super.key});

  @override
  State<RegisterTemperatureScreen> createState() => _RegisterTemperatureScreenState();
}

class _RegisterTemperatureScreenState extends State<RegisterTemperatureScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tempController = TextEditingController();
  GalponModel? _selectedShed;

  @override
  void dispose() {
    _tempController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (_selectedShed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, seleccione un galpón'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final double temp = double.parse(_tempController.text);
      context.read<TemperatureBloc>().add(
        SubmitTemperature(shedId: _selectedShed!.id, value: temp),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Injecting the service via get_it or using a new instance if not registered
    final TemperatureService service = GetIt.instance.isRegistered<TemperatureService>() 
        ? GetIt.instance<TemperatureService>() 
        : TemperatureService();

    return BlocProvider(
      create: (context) => TemperatureBloc(temperatureService: service)..add(LoadSheds()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Temperatura'),
        ),
        body: BlocConsumer<TemperatureBloc, TemperatureState>(
          listener: (context, state) {
            if (state is TemperatureSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              // Reset form
              _tempController.clear();
              setState(() {
                _selectedShed = null;
              });
              context.read<TemperatureBloc>().add(LoadSheds()); // Reload sheds if necessary
            } else if (state is TemperatureError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
              // Do not reload sheds on error usually, just let the user try again
              // But we should go back to Initial state so the form shows up again
              context.read<TemperatureBloc>().add(LoadSheds()); 
            }
          },
          builder: (context, state) {
            if (state is TemperatureLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            List<GalponModel> sheds = [];
            if (state is TemperatureInitial) {
              sheds = state.sheds;
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Complete el formulario para registrar la temperatura del galpón.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<GalponModel>(
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Galpón',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home_work),
                      ),
                      value: _selectedShed,
                      items: sheds.map((shed) {
                        return DropdownMenuItem(
                          value: shed,
                          child: Text(shed.nombre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedShed = value;
                        });
                      },
                      validator: (value) => value == null ? 'Este campo es obligatorio' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Temperatura (°C)',
                        border: OutlineInputBorder(),
                        suffixText: '°C',
                        prefixIcon: Icon(Icons.thermostat),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese la temperatura';
                        }
                        final temp = double.tryParse(value);
                        if (temp == null) {
                          return 'Ingrese un número válido';
                        }
                        if (temp < 0 || temp > 50) {
                          return 'La temperatura debe estar entre 0 y 50 °C';
                        }
                        return null;
                      },
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: state is TemperatureLoading ? null : () => _submitForm(context),
                      icon: const Icon(Icons.send),
                      label: const Text('Registrar Temperatura', style: TextStyle(fontSize: 16)),
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

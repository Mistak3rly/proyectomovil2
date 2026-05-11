// CU09: Monitorear temperatura en tiempo real
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../blocs/realtime_climate/realtime_climate_bloc.dart';
import '../services/realtime_climate_service.dart';
import '../domain/entities/realtime_climate.dart';
import '../models/galpon_model.dart';

class RealtimeClimateScreen extends StatelessWidget {
  const RealtimeClimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RealtimeClimateService service = GetIt.instance.isRegistered<RealtimeClimateService>()
        ? GetIt.instance<RealtimeClimateService>()
        : RealtimeClimateService();

    return BlocProvider(
      create: (context) => RealtimeClimateBloc(service: service)..add(StartRealtimeMonitoring()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Monitoreo en Tiempo Real'),
          // CU09: Monitorear temperatura en tiempo real
        ),
        body: const _RealtimeClimateBody(),
      ),
    );
  }
}

class _RealtimeClimateBody extends StatelessWidget {
  const _RealtimeClimateBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RealtimeClimateBloc, RealtimeClimateState>(
      builder: (context, state) {
        if (state is RealtimeClimateLoading || state is RealtimeClimateInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RealtimeClimateError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<RealtimeClimateBloc>().add(StartRealtimeMonitoring()),
                  child: const Text('Reintentar'),
                )
              ],
            ),
          );
        } else if (state is RealtimeClimateLoaded) {
          return Column(
            children: [
              _buildFilter(context, state),
              Expanded(
                child: state.filteredClimates.isEmpty
                    ? const Center(child: Text('Esperando datos de los sensores...'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: state.filteredClimates.length,
                        itemBuilder: (context, index) {
                          final climate = state.filteredClimates[index];
                          return _buildClimateCard(climate);
                        },
                      ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFilter(BuildContext context, RealtimeClimateLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: state.selectedShedId,
                hint: const Text('Todos los galpones'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todos los galpones'),
                  ),
                  ...state.sheds.map((shed) {
                    return DropdownMenuItem<int?>(
                      value: shed.id,
                      child: Text(shed.nombre),
                    );
                  }),
                ],
                onChanged: (value) {
                  context.read<RealtimeClimateBloc>().add(FilterByShed(value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClimateCard(RealtimeClimate climate) {
    Color statusColor;
    IconData statusIcon;

    switch (climate.status) {
      case ClimateStatus.optimal:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ClimateStatus.caution:
        statusColor = Colors.amber;
        statusIcon = Icons.warning;
        break;
      case ClimateStatus.critical:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  climate.shedName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(
                      climate.isSensorOnline ? Icons.wifi : Icons.wifi_off,
                      color: climate.isSensorOnline ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      climate.isSensorOnline ? 'En línea' : 'Fuera de línea',
                      style: TextStyle(
                        color: climate.isSensorOnline ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  icon: Icons.thermostat,
                  label: 'Temperatura',
                  value: climate.isSensorOnline ? '${climate.temperature.toStringAsFixed(1)}°C' : '--',
                  color: Colors.orange,
                ),
                _buildMetric(
                  icon: Icons.water_drop,
                  label: 'Humedad',
                  value: climate.isSensorOnline ? '${climate.humidity.toStringAsFixed(1)}%' : '--',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    'Estado: ${_getStatusText(climate.status)}',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getStatusText(ClimateStatus status) {
    switch (status) {
      case ClimateStatus.optimal:
        return 'Óptimo';
      case ClimateStatus.caution:
        return 'Precaución';
      case ClimateStatus.critical:
        return 'Crítico';
    }
  }
}

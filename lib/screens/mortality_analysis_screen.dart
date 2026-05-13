import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../blocs/sanidad/mortality_analysis_bloc.dart';
import '../../blocs/sanidad/mortality_analysis_state.dart';
import '../../services/sanidad_service.dart';
import '../../models/lote_model.dart';
import '../../domain/entities/mortality_record.dart';

class MortalityAnalysisScreen extends StatelessWidget {
  const MortalityAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SanidadService service = GetIt.instance.isRegistered<SanidadService>() 
        ? GetIt.instance<SanidadService>() 
        : SanidadService();

    return BlocProvider(
      create: (context) => MortalityAnalysisBloc(service: service)..add(LoadAnalysisData()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Análisis de Mortandad'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exportando reporte a PDF...')));
              },
            ),
          ],
        ),
        body: BlocBuilder<MortalityAnalysisBloc, MortalityAnalysisState>(
          builder: (context, state) {
            if (state is MortalityAnalysisLoading || state is MortalityAnalysisInitial) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MortalityAnalysisError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            } else if (state is MortalityAnalysisLoaded) {
              return _buildBody(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MortalityAnalysisLoaded state) {
    if (state.lots.isEmpty) {
      return const Center(child: Text('No hay lotes activos.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<LoteModel>(
            decoration: const InputDecoration(labelText: 'Seleccionar Lote', border: OutlineInputBorder()),
            value: state.selectedLot,
            items: state.lots.map((l) => DropdownMenuItem(value: l, child: Text(l.nombre))).toList(),
            onChanged: (val) {
              if (val != null) context.read<MortalityAnalysisBloc>().add(SelectLotForAnalysis(val));
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _KpiCard(title: 'Tasa Mortalidad', value: '${state.mortalityRate.toStringAsFixed(2)}%', color: state.mortalityRate > 5 ? Colors.red : Colors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KpiCard(title: 'Bajas Totales', value: '${state.totalDeaths}', color: Colors.blueGrey),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text('Tendencia Diaria (Últimos 15 días)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: _buildLineChart(state.records),
          ),
          const SizedBox(height: 30),
          const Text('Distribución por Causas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: _buildPieChart(state.records),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<MortalityRecord> records) {
    if (records.isEmpty) return const Center(child: Text('No hay datos suficientes'));
    
    // Agrupar por día del mes
    Map<int, int> dailyCounts = {};
    for (var r in records) {
      dailyCounts[r.timestamp.day] = (dailyCounts[r.timestamp.day] ?? 0) + r.count;
    }

    List<FlSpot> spots = dailyCounts.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 5, // Línea de referencia estándar (ej. 5 bajas / dia como umbral crítico)
              color: Colors.orange,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(show: true, labelResolver: (line) => 'Límite (5)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<MortalityRecord> records) {
    if (records.isEmpty) return const Center(child: Text('No hay datos suficientes'));

    Map<String, int> causeCounts = {};
    for (var r in records) {
      causeCounts[r.cause] = (causeCounts[r.cause] ?? 0) + r.count;
    }

    List<Color> colors = [Colors.red, Colors.blue, Colors.orange, Colors.purple, Colors.green];
    int colorIndex = 0;

    List<PieChartSectionData> sections = causeCounts.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${e.key}\n(${e.value})',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 30));
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _KpiCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

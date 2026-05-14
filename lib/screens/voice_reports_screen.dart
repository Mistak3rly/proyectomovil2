import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/reportes_service.dart';

class VoiceReportsScreen extends StatefulWidget {
  const VoiceReportsScreen({super.key});

  @override
  State<VoiceReportsScreen> createState() => _VoiceReportsScreenState();
}

class _VoiceReportsScreenState extends State<VoiceReportsScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ReportesService _reportesService = ReportesService();

  bool _isListening = false;
  String _text = 'Presiona el micrófono y habla...';
  
  List<Map<String, dynamic>> _historial = [];
  Map<String, dynamic>? _currentReport;
  String? _currentEntidad;
  String? _currentAgrupacion;
  bool _isLoading = false;

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _filtroAgruparPor;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await Permission.microphone.request();
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) {
        print('onError: $val');
        setState(() => _isListening = false);
      },
    );
    if (!available) {
      setState(() => _text = 'Reconocimiento de voz no disponible.');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = 'Escuchando...';
        });
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            if (val.hasConfidenceRating && val.confidence > 0) {
               if (!_speech.isListening) {
                 _analyzeAndFetchReport(_text);
               }
            }
          },
          localeId: 'es_ES',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _analyzeAndFetchReport(_text);
    }
  }

  void _analyzeAndFetchReport(String spokenText) async {
    final text = spokenText.toLowerCase();
    String? entidad;
    String? agruparPor;

    // 1. Identificar Entidad
    if (text.contains('mortalidad') || text.contains('mortandad')) {
      entidad = 'mortalidad';
    } else if (text.contains('alimentación') || text.contains('alimento')) {
      entidad = 'alimentacion';
    } else if (text.contains('producción') || text.contains('produccion') || text.contains('lotes')) {
      entidad = 'lotes';
    } else if (text.contains('insumos') || text.contains('inventario')) {
      entidad = 'insumos';
    } else if (text.contains('temperatura') || text.contains('clima')) {
      entidad = 'temperatura';
    } else if (text.contains('sanidad') || text.contains('sanitario')) {
      entidad = 'sanitario';
    } else if (text.contains('bitácora') || text.contains('bitacora') || text.contains('actividades')) {
      entidad = 'bitacora';
    } else if (text.contains('personal') || text.contains('empleados')) {
      entidad = 'usuarios';
    }

    // 2. Identificar Agrupación (por defecto null para mostrar registros crudos)
    if (text.contains('por mes') || text.contains('mensual')) {
      agruparPor = 'mes';
    } else if (text.contains('por dia') || text.contains('diario')) {
      agruparPor = 'dia';
    } else if (text.contains('por galpón') || text.contains('galpones')) {
      agruparPor = 'galpon';
    } else if (text.contains('por lote')) {
      agruparPor = 'lote';
    }

    if (entidad != null) {
      _fetchReportByEntity(entidad, agruparPor);
    } else {
      setState(() {
        _text = 'No entendí la entidad. Intenta decir: "Generar reporte de Mortalidad"';
      });
    }
  }

  void _fetchReportByEntity(String entidad, String? agruparPor) async {
    setState(() {
      _isLoading = true;
      _text = 'Generando reporte de $entidad ${agruparPor != null ? "agrupado por $agruparPor" : "detallado"}...';
    });

    final newHistoryItem = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'tipo': entidad.toUpperCase(),
      'descripcion': agruparPor != null ? 'Agrupado por $agruparPor' : 'Registro detallado',
      'fecha': DateTime.now(),
      'estado': 'Generando...'
    };
    
    setState(() {
      _historial.insert(0, newHistoryItem);
    });

    final fInicio = _fechaInicio != null ? DateFormat('yyyy-MM-dd').format(_fechaInicio!) : null;
    final fFin = _fechaFin != null ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : null;
    
    // Si la voz no detectó agrupación, usar el filtro visual si existe
    final agrupacionFinal = agruparPor ?? _filtroAgruparPor;

    final data = await _reportesService.generarReporte(
      entidad: entidad, 
      agruparPor: agrupacionFinal,
      fechaInicio: fInicio,
      fechaFin: fFin,
    ); // Formato JSON
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _currentReport = data;
        _currentEntidad = entidad;
        _currentAgrupacion = agrupacionFinal;
        final index = _historial.indexWhere((e) => e['id'] == newHistoryItem['id']);
        if (index != -1) {
          _historial[index]['estado'] = data != null ? 'Completado' : 'Error';
          _historial[index]['data'] = data;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes con IA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE67E22),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersDialog(context),
            tooltip: 'Filtros',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : const Color(0xFFE67E22),
        icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
        label: Text(_isListening ? 'Detener' : 'Hablar', style: const TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100, top: 16, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de IA
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology, size: 50, color: Colors.white),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asistente de Reportes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 5),
                        Text(_text, style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tarjetas de Acceso Rápido
            const Text('Generación de Reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Acceso rápido a los reportes más comunes', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildQuickCard('Inventario', 'insumos', Icons.inventory_2_outlined, Colors.green),
                _buildQuickCard('Mortandad', 'mortalidad', Icons.dangerous_outlined, Colors.red),
                _buildQuickCard('Temperatura', 'temperatura', Icons.thermostat_outlined, Colors.blue),
                _buildQuickCard('Producción', 'lotes', Icons.analytics_outlined, Colors.purple),
                _buildQuickCard('Alimentación', 'alimentacion', Icons.restaurant_menu, Colors.orange),
                _buildQuickCard('Bitácora', 'bitacora', Icons.assignment_outlined, Colors.grey),
                _buildQuickCard('Personal', 'usuarios', Icons.people_outline, Colors.teal),
                _buildQuickCard('Sanitario', 'sanitario', Icons.medical_services_outlined, Colors.cyan),
              ],
            ),

            const SizedBox(height: 20),

            // Visor del Reporte Actual
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator()))
            else if (_currentReport != null && _currentEntidad != null)
              _buildReportView(_currentEntidad!, _currentReport!),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            // Historial de Reportes
            Row(
              children: const [
                Icon(Icons.history, color: Colors.grey),
                SizedBox(width: 10),
                Text('Historial Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            if (_historial.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No hay reportes generados en esta sesión.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              )
            else
              ..._historial.map((h) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: h['estado'] == 'Completado' ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    child: Icon(Icons.insert_chart_outlined, color: h['estado'] == 'Completado' ? Colors.green : Colors.orange),
                  ),
                  title: Text(h['tipo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${h['descripcion']} • ${h['estado']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (h['data'] != null) {
                      setState(() {
                        _currentReport = h['data'];
                        _text = 'Mostrando reporte histórico de ${h['tipo']}';
                      });
                    }
                  },
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  void _showFiltersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Filtros de Reporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_fechaInicio != null ? DateFormat('dd/MM/yyyy').format(_fechaInicio!) : 'Fecha Inicio'),
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: _fechaInicio ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (date != null) {
                              setModalState(() => _fechaInicio = date);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_fechaFin != null ? DateFormat('dd/MM/yyyy').format(_fechaFin!) : 'Fecha Fin'),
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: _fechaFin ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (date != null) {
                              setModalState(() => _fechaFin = date);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Agrupar Por', border: OutlineInputBorder()),
                    value: _filtroAgruparPor,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Registro Detallado (Ninguno)')),
                      DropdownMenuItem(value: 'dia', child: Text('Por Día')),
                      DropdownMenuItem(value: 'mes', child: Text('Por Mes')),
                      DropdownMenuItem(value: 'galpon', child: Text('Por Galpón')),
                      DropdownMenuItem(value: 'lote', child: Text('Por Lote')),
                    ],
                    onChanged: (val) {
                      setModalState(() => _filtroAgruparPor = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _fechaInicio = null;
                              _fechaFin = null;
                              _filtroAgruparPor = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Limpiar', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Aplicar estado
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildQuickCard(String title, String entity, IconData icon, Color color) {
    return InkWell(
      onTap: () => _fetchReportByEntity(entity, entity == 'mortalidad' ? 'dia' : null),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportView(String entidad, Map<String, dynamic> data) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final rows = data['rows'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Resumen Ejecutivó', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _generateAndSharePDF(entidad, data),
                  tooltip: 'Exportar PDF',
                ),
                IconButton(
                  icon: const Icon(Icons.table_view, color: Colors.green),
                  onPressed: () => _downloadExcel(entidad, _currentAgrupacion),
                  tooltip: 'Exportar Excel',
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: summary.entries.where((e) => e.value is! Map && e.value is! List).map((e) {
            String value = e.value.toString();
            if (e.value is double) value = (e.value as double).toStringAsFixed(2);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                ],
              ),
            );
          }).toList(),
        ),
        
        // Agregar el gráfico aquí
        if (rows.isNotEmpty) _buildChart(rows),

        const SizedBox(height: 25),
        const Text('Detalle de Registros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: rows.isEmpty 
            ? const Center(child: Text('Sin datos'))
            : ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = rows[index] as Map<String, dynamic>;
                return ExpansionTile(
                  title: Text(row['periodo']?.toString() ?? 'Registro #${index+1}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: row.entries
                    .where((e) => e.key != 'periodo')
                    .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: const TextStyle(color: Colors.grey)),
                          Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )).toList(),
                );
              },
          ),
        ),
      ],
    );
  }

  Widget _buildChart(List<dynamic> rows) {
    if (rows.isEmpty) return const SizedBox();

    // Encontrar la primera clave numérica que no sea un ID
    String? valueKey;
    final firstRow = rows.first as Map<String, dynamic>;
    for (final key in firstRow.keys) {
      if (key == 'periodo' || key.contains('id')) continue;
      final val = firstRow[key];
      if (val is num || (val is String && double.tryParse(val) != null)) {
        valueKey = key;
        break;
      }
    }

    if (valueKey == null) return const SizedBox();

    // Tomar máximo los últimos 7 registros para que se vea bien
    final chartRows = rows.reversed.take(7).toList().reversed.toList();
    
    double maxY = 0;
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < chartRows.length; i++) {
      final row = chartRows[i] as Map<String, dynamic>;
      final rawVal = row[valueKey];
      final val = rawVal is num ? rawVal.toDouble() : double.tryParse(rawVal.toString()) ?? 0.0;
      
      if (val > maxY) maxY = val;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              color: Colors.orange,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        )
      );
    }

    if (barGroups.isEmpty || maxY == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Row(
          children: [
            const Icon(Icons.bar_chart, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Gráfico: ${valueKey.replaceAll('_', ' ').toUpperCase()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 15),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < chartRows.length) {
                        final row = chartRows[value.toInt()] as Map<String, dynamic>;
                        final label = row['periodo']?.toString() ?? row['galpon']?.toString() ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label.length > 5 ? label.substring(0, 5) : label,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _downloadExcel(String entidad, String? agruparPor) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando Excel...')));
    final fInicio = _fechaInicio != null ? DateFormat('yyyy-MM-dd').format(_fechaInicio!) : null;
    final fFin = _fechaFin != null ? DateFormat('yyyy-MM-dd').format(_fechaFin!) : null;
    final bytes = await _reportesService.descargarReporteExcel(
      entidad: entidad,
      agruparPor: agruparPor,
      fechaInicio: fInicio,
      fechaFin: fFin,
    );
    if (bytes != null) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Reporte_${entidad.toUpperCase()}.xlsx');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Aquí tienes el reporte de $entidad');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al descargar Excel')));
    }
  }

  void _generateAndSharePDF(String entidad, Map<String, dynamic> data) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando PDF...')));
    final pdf = pw.Document();
    
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final rows = data['rows'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('AviGranja MS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                  pw.Text('Reporte de ${entidad.toUpperCase()}', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ]
              )
            ),
            pw.SizedBox(height: 20),
            pw.Text('RESUMEN EJECUTIVO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Wrap(
              spacing: 10,
              runSpacing: 10,
              children: summary.entries.where((e) => e.value is! Map && e.value is! List).map((e) {
                return pw.Container(
                  width: 150,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(e.key.replaceAll('_', ' ').toUpperCase(), style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                      pw.SizedBox(height: 4),
                      pw.Text(e.value is double ? (e.value as double).toStringAsFixed(2) : e.value.toString(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ]
                  )
                );
              }).toList()
            ),
            pw.SizedBox(height: 30),
            pw.Text('DETALLE DE REGISTROS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            if (rows.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                headers: (rows.first as Map<String, dynamic>).keys.toList(),
                data: rows.map((r) => (r as Map<String, dynamic>).values.map((v) => v.toString()).toList()).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                cellAlignment: pw.Alignment.centerLeft,
              )
            ] else ...[
              pw.Text('No hay registros para mostrar.')
            ]
          ];
        }
      )
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Reporte_${entidad.toUpperCase()}.pdf');
  }
}

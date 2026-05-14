import 'package:flutter/material.dart';
import '../services/sanidad_service.dart';
import '../models/lote_model.dart';

class LotesScreen extends StatefulWidget {
  const LotesScreen({super.key});

  @override
  State<LotesScreen> createState() => _LotesScreenState();
}

class _LotesScreenState extends State<LotesScreen> {
  final SanidadService _sanidadService = SanidadService();
  List<LoteModel> _lotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLotes();
  }

  Future<void> _loadLotes() async {
    setState(() => _isLoading = true);
    try {
      final lotes = await _sanidadService.getActiveLots();
      if (mounted) {
        setState(() {
          _lotes = lotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando lotes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 20),
            const Text('No hay lotes activos', style: TextStyle(fontSize: 18, color: Colors.grey)),
            TextButton(onPressed: _loadLotes, child: const Text('Reintentar'))
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLotes,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _lotes.length,
        itemBuilder: (context, index) {
          final lote = _lotes[index];
          final double mortalidad = lote.poblacionInicial > 0 
              ? ((lote.poblacionInicial - lote.poblacionActual) / lote.poblacionInicial) * 100 
              : 0.0;
          
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lote #${lote.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3436))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getColorForEstado(lote.estado ?? 'Desconocido'),
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(
                          lote.estado ?? 'Desconocido', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      )
                    ],
                  ),
                  const Divider(height: 30),
                  _buildInfoRow(Icons.warehouse, 'Galpón', 'ID: ${lote.idGalpon}'),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.pets, 'Raza/Tipo', lote.razaTipo),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.timeline, 'Aves Actuales', '${lote.poblacionActual} / ${lote.poblacionInicial}'),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.trending_down, 
                    'Mortalidad', 
                    '${mortalidad.toStringAsFixed(2)}%', 
                    color: mortalidad > 5 ? Colors.red : Colors.green
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.calendar_today, 'Ingreso', lote.fechaIngreso.toLocal().toString().split(' ')[0]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black87),
            textAlign: TextAlign.right,
          )
        ),
      ],
    );
  }

  Color _getColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'crianza':
      case 'crecimiento':
        return Colors.blue;
      case 'engorde':
        return Colors.orange;
      case 'activo':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

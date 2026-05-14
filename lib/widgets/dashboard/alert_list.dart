import 'package:flutter/material.dart';

class AlertList extends StatelessWidget {
  final List<dynamic> insumosCriticos;

  const AlertList({super.key, required this.insumosCriticos});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> alerts = insumosCriticos.map((insumo) {
      return {
        'title': 'Stock Crítico: ${insumo['nombre']}',
        'desc': 'Quedan ${insumo['stock_actual']} ${insumo['unidad_medida']} (Mínimo: ${insumo['stock_minimo']})',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.redAccent,
      };
    }).toList();

    if (alerts.isEmpty) {
      return const SizedBox(); // No mostrar nada si no hay alertas
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Alertas Recientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...alerts.map((alert) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: alert['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: alert['color'].withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(alert['icon'], color: alert['color']),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: alert['color'],
                          ),
                        ),
                        Text(
                          alert['desc'],
                          style: TextStyle(color: Colors.grey[800], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            )),
      ],
    );
  }
}

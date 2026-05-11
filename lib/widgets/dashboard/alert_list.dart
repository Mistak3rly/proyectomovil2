import 'package:flutter/material.dart';

class AlertList extends StatelessWidget {
  const AlertList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> alerts = [
      {
        'title': 'Temperatura Alta',
        'desc': 'Galpón 3 superó los 28°C.',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.redAccent,
      },
      {
        'title': 'Stock Bajo',
        'desc': 'Quedan 2 días de alimento.',
        'icon': Icons.inventory_2_outlined,
        'color': Colors.orangeAccent,
      },
    ];

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

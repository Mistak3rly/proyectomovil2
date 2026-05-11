import 'package:flutter/material.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tasks = [
      {
        'task': 'Desinfección de Galpón 2',
        'time': '10:00 AM',
        'isDone': false,
      },
      {
        'task': 'Control de Camada Sect. A',
        'time': '11:30 AM',
        'isDone': true,
      },
      {
        'task': 'Registro de Mortalidad',
        'time': '02:00 PM',
        'isDone': false,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Próximas Tareas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: task['isDone'] ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task['isDone'] ? Icons.check_circle_outline : Icons.pending_actions,
                    color: task['isDone'] ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                ),
                title: Text(
                  task['task'],
                  style: TextStyle(
                    decoration: task['isDone'] ? TextDecoration.lineThrough : null,
                    color: task['isDone'] ? Colors.grey : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(task['time'], style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.more_vert, size: 20),
              );
            },
          ),
        ),
      ],
    );
  }
}

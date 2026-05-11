import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../widgets/dashboard/operator_drawer.dart';
import '../widgets/dashboard/kpi_card.dart';
import '../widgets/dashboard/alert_list.dart';
import '../widgets/dashboard/task_list.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 2; // Inicio es el icono central (indice 2)

  // Lista de vistas para las 5 subdivisiones
  final List<Widget> _views = [
    const _PlaceholderView(title: 'Producción (Lotes)', icon: Icons.analytics_outlined),
    const _PlaceholderView(title: 'Alimentación', icon: Icons.restaurant_menu),
    const _HomeView(), // Inicio (Dashboard)
    const _SanidadView(), // Sanidad
    const _IotView(), // Ambiente (IoT)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AviGranja Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE67E22),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const OperatorDrawer(),
      body: _views[_selectedIndex],
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: const Color(0xFFE67E22),
        activeColor: Colors.white,
        color: Colors.white70,
        style: TabStyle.fixedCircle,
        initialActiveIndex: _selectedIndex,
        items: const [
          TabItem(icon: Icons.analytics_outlined, title: 'Lotes'),
          TabItem(icon: Icons.restaurant_menu, title: 'Ali.'),
          TabItem(icon: Icons.home, title: 'Inicio'),
          TabItem(icon: Icons.medical_services_outlined, title: 'San.'),
          TabItem(icon: Icons.thermostat_outlined, title: 'IoT'),
        ],
        onTap: (int i) {
          setState(() {
            _selectedIndex = i;
          });
        },
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mensaje de Bienvenida
          const Text(
            "Buen día, Operario",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
          ),
          const Text("Aquí tienes un vistazo de tus galpones"),
          const SizedBox(height: 25),

          // Tarjetas de Resumen (KPIs)
          const Text(
            "Resumen Operativo",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                KPICard(
                  title: "Población Total",
                  value: "15,420",
                  icon: Icons.egg_outlined,
                ),
                KPICard(
                  title: "Clima Actual",
                  value: "28°C / 65%",
                  icon: Icons.thermostat,
                  color: Colors.blueAccent,
                ),
                KPICard(
                  title: "Alimento (Stock)",
                  value: "450 Kg",
                  icon: Icons.inventory_2,
                  color: Colors.green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Alertas
          const AlertList(),

          const SizedBox(height: 30),

          // Tareas
          const TaskList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PlaceholderView({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text("Funcionalidad en desarrollo"),
        ],
      ),
    );
  }
}

class _IotView extends StatelessWidget {
  const _IotView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Control Ambiental IoT',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
          ),
          const SizedBox(height: 10),
          const Text('Gestión y monitoreo de las condiciones de los galpones.'),
          const SizedBox(height: 30),
          
          _buildActionCard(
            context,
            title: 'Registrar Temperatura',
            description: 'Capturar y validar temperatura del galpón manualmente.',
            icon: Icons.thermostat,
            color: Colors.orange,
            route: '/register_temperature',
          ),
          const SizedBox(height: 20),
          
          _buildActionCard(
            context,
            title: 'Monitoreo en Vivo',
            description: 'Visualizar el estado del clima y los sensores en tiempo real.',
            icon: Icons.monitor_heart,
            color: Colors.blueAccent,
            route: '/realtime_climate',
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required String route}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(description, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _SanidadView extends StatelessWidget {
  const _SanidadView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Control de Sanidad',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
          ),
          const SizedBox(height: 10),
          const Text('Gestión de mortalidad, tratamientos y vacunación.'),
          const SizedBox(height: 30),
          
          _buildActionCard(
            context,
            title: 'Registrar Mortandad (CU13)',
            description: 'Reportar bajas de aves en el galpón.',
            icon: Icons.dangerous_outlined,
            color: Colors.redAccent,
            route: '/register_mortality',
          ),
          const SizedBox(height: 16),
          
          _buildActionCard(
            context,
            title: 'Analizar Mortandad (CU14)',
            description: 'Visualizar tasas y tendencias críticas.',
            icon: Icons.analytics_outlined,
            color: Colors.purple,
            route: '/mortality_analysis',
          ),
          const SizedBox(height: 16),
          
          _buildActionCard(
            context,
            title: 'Tratamientos y Vacunas',
            description: 'Registrar y visualizar actividades sanitarias.',
            icon: Icons.vaccines,
            color: Colors.teal,
            route: '/sanidad_activities',
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String description, required IconData icon, required Color color, required String route}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(description, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

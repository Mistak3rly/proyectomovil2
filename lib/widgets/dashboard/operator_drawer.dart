import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OperatorDrawer extends StatelessWidget {
  const OperatorDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header del Perfil
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFE67E22),
              image: DecorationImage(
                image: AssetImage('assets/fondo.png'),
                fit: BoxFit.cover,
                opacity: 0.3,
              ),
            ),
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            accountName: const Text(
              "Operario Juan Perez",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text("CI: 1234567 LP | Cargo: Operario SR"),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.gps_fixed,
                  title: 'Control de Asistencia',
                  subtitle: 'Marcar entrada/salida (GPS)',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  subtitle: 'Notificaciones y modo oscuro',
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Soporte Técnico',
                  subtitle: 'Contacto con administrador',
                  onTap: () {},
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar Sesión',
                  subtitle: 'Salir de forma segura',
                  color: Colors.redAccent,
                  onTap: () {
                    context.go('/');
                  },
                ),
              ],
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Versión 1.0.0+1 - AviGranja 2026",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = const Color(0xFF2D3436),
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }
}

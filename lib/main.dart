import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movil_avicola/router/router.dart';
import 'screens/login_screen.dart'; // Asegúrate de haber creado este archivo
// import 'screens/dashboard_screen.dart'; // Crea este para el CU07

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AviGranja Móvil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Usamos naranja como color principal según la identidad visual (pág. 55)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      // El home ahora es un verificador de sesión activa
      routerConfig: router,
    );
  }
}

/// Widget encargado de decidir si mostrar Login o Dashboard (CU01/CU02)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  final _storage = const FlutterSecureStorage();
  //autenticacion avanzada RNF-10

  Future<String?> _checkToken() async {
    // RNF-02: Protección de la información almacenada 
    return await _storage.read(key: 'jwt_token');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>( //sistema no queda bloqueado mientras se verifica respetando RNF-05 sobre rendimiento
      future: _checkToken(),
      builder: (context, snapshot) {
        // Mientras el sistema procesa (RNF-05: Tiempo de respuesta < 2s) 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay token, el usuario ya inició sesión previamente
        if (snapshot.hasData && snapshot.data != null) {
          // Por ahora devolvemos un placeholder del Dashboard (CU07)
          return const PlaceholderScreen(title: "Dashboard de Galpones");
        }

        // Si no hay token, redirigir al Login (RF-01) [cite: 601]
        return const LoginScreen();
      },
    );
  }
}

/// Pantalla temporal mientras creas el Dashboard oficial
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.orange),
      body: const Center(child: Text("Bienvenido a AviGranja")),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:movil_avicola/models/user_model.dart';
import '../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController(text: 'juan');
  final TextEditingController _passwordController =
      TextEditingController(text: '12345');
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    // Definimos el factor de división (60% arriba, 40% abajo)
    final double topHeight = MediaQuery.of(context).size.height * 0.6;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Imagen de fondo y superposición naranja (Solo en la parte superior)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height:
                topHeight +
                50, // Un poco más para que el redondeado no muestre blanco
            child: Stack(
              children: [
                // Imagen de fondo
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/fondo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Superposición naranja semitransparente (Baja opacidad)
                Container(color: Colors.orange.withOpacity(0.45)),

                // Branding (Logo y Títulos)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Circular
                      Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "AviGranja",
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Text(
                        "SISTEMA DE GESTIÓN AVÍCOLA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Sección de Login (Cuerpo blanco con esquinas redondeadas)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height:
                  MediaQuery.of(context).size.height *
                  0.50, // Ajustado para dar aire
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 30.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ingresa tus credenciales para continuar",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 30),

                    _buildField(
                      _userController,
                      "Usuario",
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      _passwordController,
                      "Contraseña",
                      Icons.lock_outline,
                      isPass: true,
                    ),

                    const SizedBox(height: 35),

                    // Botón Naranja Estilizado
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _handleLogin(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE67E22),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color(0xFFE67E22).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Ingresar al Sistema",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "UAGRM - Sistema Avícola 2026",
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para campos responsivos
  Widget _buildField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool isPass = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color.fromARGB(255, 245, 245, 245),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    Usuario? res = await _authService.login(
      _userController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (res != null) {
      print('Inicio de sesión exitoso');
      print('nombre usuario : ${res.nomUsuario}');
      print('email : ${res.email}');
      print('tipo usuario : ${res.tipoUsuario}');
      print('estado : ${res.estado}');
      if (context.mounted) context.go('/dashboard');
    } else {
      print('Error al iniciar sesión');
    }
  }
}

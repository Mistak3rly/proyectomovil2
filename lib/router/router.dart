import 'package:go_router/go_router.dart';
import 'package:movil_avicola/screens/dashboard_screen.dart';
import 'package:movil_avicola/screens/login_screen.dart';

final router = GoRouter(
  initialLocation: '/dashboard',
  routes: [
  GoRoute(
    path: '/',
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/dashboard',
    builder: (context, state) => const DashboardScreen(),
  ),
]

);
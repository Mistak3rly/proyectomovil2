import 'package:go_router/go_router.dart';
import 'package:movil_avicola/screens/dashboard_screen.dart';
import 'package:movil_avicola/screens/login_screen.dart';
import 'package:movil_avicola/screens/register_temperature_screen.dart';
import 'package:movil_avicola/screens/realtime_climate_screen.dart';
import 'package:movil_avicola/screens/register_mortality_screen.dart';
import 'package:movil_avicola/screens/mortality_analysis_screen.dart';
import 'package:movil_avicola/screens/sanidad_activities_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/register_temperature',
      builder: (context, state) => const RegisterTemperatureScreen(),
    ),
    GoRoute(
      path: '/realtime_climate',
      builder: (context, state) => const RealtimeClimateScreen(),
    ),
    GoRoute(
      path: '/register_mortality',
      builder: (context, state) => const RegisterMortalityScreen(),
    ),
    GoRoute(
      path: '/mortality_analysis',
      builder: (context, state) => const MortalityAnalysisScreen(),
    ),
    GoRoute(
      path: '/sanidad_activities',
      builder: (context, state) => const SanidadActivitiesScreen(),
    ),
  ]
);
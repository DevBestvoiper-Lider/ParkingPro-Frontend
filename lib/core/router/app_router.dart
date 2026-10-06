import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/bienvenida_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/registro_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/mapa/presentation/mapa_screen.dart';
import '../../features/reservas/presentation/mis_reservas_screen.dart';
import '../../features/nueva_reserva/presentation/nueva_reserva_screen.dart';
import '../../features/perfil/presentation/mis_vehiculos_screen.dart';
import '../../features/perfil/presentation/perfil_screen.dart';
import '../../features/shell/presentation/shell_screen.dart';
import '../widgets/proximamente.dart';

const _rutasDeAcceso = {'/bienvenida', '/login', '/registro'};

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evalúa las redirecciones cada vez que cambia la sesión.
  final cambiosDeSesion = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => cambiosDeSesion.value++);
  ref.onDispose(cambiosDeSesion.dispose);

  return GoRouter(
    initialLocation: '/inicio',
    refreshListenable: cambiosDeSesion,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final ruta = state.matchedLocation;
      final enAcceso = _rutasDeAcceso.contains(ruta);

      // Cargando la sesión guardada o sin conexión: la bienvenida muestra el estado.
      if (!auth.hasValue) return ruta == '/bienvenida' ? null : '/bienvenida';

      final sesion = auth.value;
      if (sesion == null) return enAcceso ? null : '/bienvenida';
      if (sesion.esInvitado) return ruta == '/bienvenida' ? '/mapa' : null;
      return enAcceso ? '/inicio' : null;
    },
    routes: [
      GoRoute(path: '/bienvenida', builder: (_, _) => const BienvenidaScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/registro', builder: (_, _) => const RegistroScreen()),
      GoRoute(
        path: '/reservas/nueva',
        builder: (_, estado) =>
            NuevaReservaScreen(sedeId: estado.uri.queryParameters['sede']),
      ),
      GoRoute(
        path: '/sesion/:id',
        builder: (_, _) => const Proximamente(
          titulo: 'Sesión Activa',
          icono: Icons.timer_outlined,
        ),
      ),
      GoRoute(
        path: '/notificaciones',
        builder: (_, _) => const Proximamente(
          titulo: 'Notificaciones',
          icono: Icons.notifications_none_rounded,
        ),
      ),
      GoRoute(
        path: '/planes',
        builder: (_, _) => const Proximamente(
          titulo: 'Planes',
          icono: Icons.workspace_premium_outlined,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navegacion) => ShellScreen(navegacion: navegacion),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/inicio', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reservas',
                builder: (_, _) => const MisReservasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/mapa', builder: (_, _) => const MapaScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mis-plazas',
                builder: (_, _) => const MisVehiculosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/perfil', builder: (_, _) => const PerfilScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});

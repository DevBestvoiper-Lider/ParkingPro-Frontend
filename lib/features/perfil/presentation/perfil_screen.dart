import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).value?.usuario;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (usuario == null) ...[
            const Text(
              'Estás usando ParkingPro como invitado.',
              style: TextStyle(color: AppColors.textoTenue),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/login'),
              child: const Text('Iniciar Sesión'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.push('/registro'),
              child: const Text('Registrarme'),
            ),
          ] else ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primario,
                  child: Text(
                    usuario.nombre.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  usuario.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  [
                    usuario.email,
                    if (usuario.telefono != null) usuario.telefono!,
                  ].join('\n'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.directions_car_outlined),
                    title: const Text('Mis vehículos'),
                    trailing: Text('${usuario.vehiculos.length}'),
                    onTap: () => context.go('/mis-plazas'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Plan y suscripción'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/planes'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_rounded),
                    title: const Text('Notificaciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/notificaciones'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).cerrarSesion(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ],
      ),
    );
  }
}

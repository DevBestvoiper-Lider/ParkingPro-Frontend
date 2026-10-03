import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/logo.dart';
import 'auth_controller.dart';

/// Splash del mockup: logo, "Iniciar Sesión", "Registrarme" y "Continuar como invitado".
class BienvenidaScreen extends ConsumerWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle
          .light, // íconos de la barra de estado en blanco sobre el azul
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: degradadoMarca),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      const LogoParkingPro(),
                      const SizedBox(height: 16),
                      const Text(
                        'ParkingPro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tu parqueadero siempre contigo',
                        style: TextStyle(
                          color: AppColors.azulSuave,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 48),
                      if (auth.isLoading)
                        const CircularProgressIndicator(color: Colors.white)
                      else if (auth.hasError)
                        _SinConexion(
                          mensaje: ApiException.desde(auth.error!).mensaje,
                          alReintentar: () =>
                              ref.invalidate(authControllerProvider),
                        )
                      else
                        _Botones(ref: ref),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primarioOscuro,
          ),
          onPressed: () => context.push('/login'),
          child: const Text('Iniciar Sesión'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0x80FFFFFF), width: 1.5),
          ),
          onPressed: () => context.push('/registro'),
          child: const Text('Registrarme'),
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.azulSuave),
          onPressed: () =>
              ref.read(authControllerProvider.notifier).continuarComoInvitado(),
          child: const Text('Continuar como invitado'),
        ),
      ],
    );
  }
}

class _SinConexion extends StatelessWidget {
  const _SinConexion({required this.mensaje, required this.alReintentar});

  final String mensaje;
  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 36),
        const SizedBox(height: 8),
        Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primarioOscuro,
          ),
          onPressed: alReintentar,
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}

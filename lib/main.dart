import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'features/auth/presentation/auth_controller.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        // Si la API responde 401 (token vencido), se cierra la sesión y el router vuelve a la bienvenida.
        alExpirarSesionProvider.overrideWith(
          (ref) =>
              () => ref.read(authControllerProvider.notifier).expirarSesion(),
        ),
      ],
      child: const ParkingProApp(),
    ),
  );
}

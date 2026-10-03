import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingpro/app.dart';
import 'package:parkingpro/core/storage/token_storage.dart';
import 'package:parkingpro/features/auth/data/auth_repository.dart';
import 'package:parkingpro/core/network/tiempo_real.dart';
import 'package:parkingpro/core/storage/dispositivo.dart';
import 'package:parkingpro/features/nueva_reserva/data/nueva_reserva_repository.dart';
import 'package:parkingpro/features/mapa/data/mapa_repository.dart';
import 'package:parkingpro/features/mapa/presentation/mapa_providers.dart';
import 'package:parkingpro/features/reservas/data/reservas_repository.dart';

import 'fakes.dart';

/// Overrides comunes: sin red, sin GPS y sin mosaicos del mapa.
List overridesBase({
  String? token,
  MapaFalso? mapa,
  NuevaReservaFalso? reservas,
}) => [
  tokenStorageProvider.overrideWithValue(TokensEnMemoria(token)),
  authRepositoryProvider.overrideWithValue(AuthFalso()),
  reservasRepositoryProvider.overrideWithValue(ReservasFalso()),
  mapaRepositoryProvider.overrideWithValue(mapa ?? MapaFalso()),
  ubicacionProvider.overrideWith(
    (ref) async => const Ubicacion(centroCartagena, real: true),
  ),
  dispositivoIdProvider.overrideWith((ref) async => 'dispositivo-de-prueba'),
  mostrarMosaicosProvider.overrideWithValue(false),
  nuevaReservaRepositoryProvider.overrideWithValue(
    reservas ?? NuevaReservaFalso(),
  ),
  eventosSedeProvider.overrideWith((ref, sedeId) => const Stream.empty()),
];

Future<void> abrirApp(
  WidgetTester tester, {
  String? token,
  MapaFalso? mapa,
  NuevaReservaFalso? reservas,
}) => _abrirApp(tester, token: token, mapa: mapa, reservas: reservas);

Future<void> esperar(WidgetTester tester) => _esperar(tester);

Future<void> _abrirApp(
  WidgetTester tester, {
  String? token,
  MapaFalso? mapa,
  NuevaReservaFalso? reservas,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesBase(
        token: token,
        mapa: mapa,
        reservas: reservas,
      ).cast(),
      child: const ParkingProApp(fuentesDeGoogle: false),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('sin sesión muestra la bienvenida', (tester) async {
    await _abrirApp(tester);
    expect(find.text('ParkingPro'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
    expect(find.text('Continuar como invitado'), findsOneWidget);
  });

  testWidgets('login correcto lleva a Inicio con el resumen', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Iniciar Sesión'));
    await _esperar(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'carlos@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'secreto123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar Sesión'));
    await _esperar(tester);

    expect(find.text('Hola, Carlos 👋'), findsOneWidget);
    expect(find.text('⭐ Plan Afiliado'), findsOneWidget);
    expect(find.text('Reservas'), findsWidgets);
    expect(find.text('2'), findsOneWidget); // reservas próximas
    expect(find.text('No tienes un vehículo parqueado ahora.'), findsOneWidget);
  });

  testWidgets('login con contraseña incorrecta muestra el error', (
    tester,
  ) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Iniciar Sesión'));
    await _esperar(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'carlos@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'mala',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar Sesión'));
    await _esperar(tester);
    expect(find.text('Credenciales inválidas'), findsOneWidget);
  });

  testWidgets('valida el formulario antes de llamar a la API', (tester) async {
    await _abrirApp(tester);
    await tester.tap(find.text('Iniciar Sesión'));
    await _esperar(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'no-es-email',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar Sesión'));
    await _esperar(tester);
    expect(find.text('Email no válido'), findsOneWidget);
    expect(find.text('Escribe tu contraseña'), findsOneWidget);
  });

  testWidgets('con token guardado entra directo a Inicio', (tester) async {
    await _abrirApp(tester, token: 'guardado');
    await _esperar(tester);
    expect(find.text('Hola, Carlos 👋'), findsOneWidget);
  });

  testWidgets(
    'invitado entra al mapa y ve la invitación a registrarse en Inicio',
    (tester) async {
      await _abrirApp(tester);
      await tester.tap(find.text('Continuar como invitado'));
      await _esperar(tester);
      expect(find.text('Buscar parqueadero...'), findsOneWidget); // el mapa

      await tester.tap(find.text('Inicio'));
      await _esperar(tester);
      expect(find.text('Crea tu cuenta para reservar'), findsOneWidget);
    },
  );

  testWidgets('cerrar sesión vuelve a la bienvenida', (tester) async {
    await _abrirApp(tester, token: 'guardado');
    await _esperar(tester);
    await tester.tap(find.text('Perfil'));
    await _esperar(tester);
    await tester.tap(find.text('Cerrar sesión'));
    await _esperar(tester);
    expect(find.text('Continuar como invitado'), findsOneWidget);
  });
}

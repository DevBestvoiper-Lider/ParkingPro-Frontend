import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';
import 'flujo_test.dart' show abrirApp, esperar;

Future<void> _irAlMapa(
  WidgetTester tester, {
  String? token,
  MapaFalso? mapa,
}) async {
  await abrirApp(tester, token: token, mapa: mapa);
  if (token == null) {
    await tester.tap(find.text('Continuar como invitado'));
  } else {
    await esperar(tester);
    await tester.tap(find.text('Mapa'));
  }
  await esperar(tester);
}

void main() {
  testWidgets('muestra un pin de precio por sede y el botón de lista', (
    tester,
  ) async {
    await _irAlMapa(tester);
    expect(find.text(r'$4.5k/h'), findsOneWidget);
    expect(find.text(r'$6.0k/h'), findsOneWidget);
    expect(find.text('Tú'), findsOneWidget);
    expect(find.text('Ver lista · 2 lugares'), findsOneWidget);
  });

  testWidgets('tocar un pin abre la tarjeta con cupos e interesados', (
    tester,
  ) async {
    final mapa = MapaFalso();
    await _irAlMapa(tester, mapa: mapa);
    await tester.tap(find.text(r'$4.5k/h'));
    await esperar(tester);

    expect(find.text('Sede Centro Histórico'), findsOneWidget);
    expect(find.text('45 libres'), findsOneWidget);
    expect(find.text('3 personas están viendo este lugar'), findsOneWidget);
    expect(mapa.intereses, ['s1']);
    expect(find.text('Cómo llegar'), findsOneWidget);
  });

  testWidgets('una sede llena no deja reservar', (tester) async {
    await _irAlMapa(tester);
    await tester.tap(find.text(r'$6.0k/h'));
    await esperar(tester);
    expect(find.text('Lleno'), findsOneWidget);
    final boton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Reservar'),
    );
    expect(boton.onPressed, isNull);
  });

  testWidgets('el invitado debe iniciar sesión para reservar', (tester) async {
    await _irAlMapa(tester);
    await tester.tap(find.text(r'$4.5k/h'));
    await esperar(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
    await esperar(tester);
    expect(find.text('Inicia sesión para reservar'), findsOneWidget);
  });

  testWidgets('la lista muestra las sedes y al elegir una abre su tarjeta', (
    tester,
  ) async {
    await _irAlMapa(tester);
    await tester.tap(find.text('Ver lista · 2 lugares'));
    await esperar(tester);
    expect(find.text('2 parqueaderos cercanos'), findsOneWidget);
    expect(find.textContaining('160 m'), findsOneWidget);

    await tester.tap(find.text('Sede Bocagrande'));
    await esperar(tester);
    expect(find.text('2 parqueaderos cercanos'), findsNothing);
    expect(find.text('Lleno'), findsOneWidget);
  });

  testWidgets('buscar y filtrar vuelven a consultar la API', (tester) async {
    final mapa = MapaFalso();
    await _irAlMapa(tester, mapa: mapa);

    await tester.enterText(find.byType(TextField), 'boca');
    await tester.pump(const Duration(milliseconds: 500));
    await esperar(tester);
    expect(mapa.consultas.last.texto, 'boca');
    expect(find.text('Ver lista · 1 lugar'), findsOneWidget);

    await tester.tap(find.text('Filtros'));
    await esperar(tester);
    await tester.tap(find.text('Moto'));
    await tester.tap(find.text('10 km'));
    await tester.tap(find.text('Aplicar'));
    await esperar(tester);
    expect(
      (mapa.consultas.last.tipo, mapa.consultas.last.radioKm),
      ('moto', 10.0),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingpro/features/nueva_reserva/domain/modelos.dart';
import 'package:parkingpro/features/nueva_reserva/presentation/nueva_reserva_providers.dart';

import 'fakes.dart';
import 'flujo_test.dart' show abrirApp, esperar;

/// Inicia sesión, abre el mapa, toca la sede del Centro y "Reservar".
Future<void> _reservarDesdeElMapa(
  WidgetTester tester,
  NuevaReservaFalso reservas,
) async {
  await abrirApp(tester, token: 'guardado', reservas: reservas);
  await esperar(tester);
  await tester.tap(find.text('Mapa'));
  await esperar(tester);
  await tester.tap(find.text(r'$4.5k/h'));
  await esperar(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Reservar'));
  await esperar(tester);
}

Future<void> _elegirPlazaYContinuar(WidgetTester tester) async {
  await tester.tap(find.text('Buscar Disponibilidad'));
  await esperar(tester);
  await tester.tap(find.text('02'));
  await esperar(tester);
  await tester.tap(find.text('Continuar'));
  await esperar(tester);
}

void main() {
  group('reglas', () {
    test('se cobra por hora o fracción, mínimo 1 hora, con descuento', () {
      final inicio = DateTime(2026, 10, 1, 10);
      expect(
        estimarTotal(
          valorHora: 4500,
          inicio: inicio,
          fin: inicio.add(const Duration(hours: 2)),
        ),
        9000,
      );
      expect(
        estimarTotal(
          valorHora: 4500,
          inicio: inicio,
          fin: inicio.add(const Duration(minutes: 61)),
        ),
        9000,
      );
      expect(
        estimarTotal(
          valorHora: 4500,
          inicio: inicio,
          fin: inicio.add(const Duration(minutes: 20)),
        ),
        4500,
      );
      expect(
        estimarTotal(
          valorHora: 4500,
          inicio: inicio,
          fin: inicio.add(const Duration(hours: 2)),
          descuentoPct: 15,
        ),
        7650,
      );
    });

    test('la salida antes de la entrada es al día siguiente', () {
      final b = BorradorReserva(
        fecha: DateTime(2026, 10, 1),
        entrada: const TimeOfDay(hour: 22, minute: 0),
        salida: const TimeOfDay(hour: 1, minute: 30),
      );
      expect(b.fin, DateTime(2026, 10, 2, 1, 30));
      expect(b.duracion, const Duration(hours: 3, minutes: 30));
    });

    test(
      'el borrador inicial empieza en el próximo cuarto de hora y dura 2 horas',
      () {
        final b = BorradorReserva.inicial(DateTime(2026, 10, 1, 9, 7));
        expect(b.inicio, DateTime(2026, 10, 1, 9, 15));
        expect(b.fin, DateTime(2026, 10, 1, 11, 15));
      },
    );
  });

  testWidgets('desde el mapa: la sede y el vehículo vienen elegidos', (
    tester,
  ) async {
    await _reservarDesdeElMapa(tester, NuevaReservaFalso());
    expect(find.text('Nueva Reserva'), findsOneWidget);
    expect(
      find.text('Sede Centro Histórico · ParkingPro Cartagena'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ChoiceChip, 'ABC123'), findsOneWidget);
    expect(find.text(r'Total: $9.000'), findsOneWidget);
  });

  testWidgets('elegir plaza y pagar ahora confirma la reserva', (tester) async {
    final reservas = NuevaReservaFalso();
    await _reservarDesdeElMapa(tester, reservas);

    await tester.tap(find.text('Buscar Disponibilidad'));
    await esperar(tester);
    expect(find.text('Selecciona tu Plaza'), findsOneWidget);
    expect(find.text('ZONA A · 1 libres de 3'), findsOneWidget);

    // Las plazas ocupadas o reservadas no se pueden elegir
    await tester.tap(find.text('01'));
    await esperar(tester);
    expect(find.text('Toca una plaza verde'), findsOneWidget);

    await tester.tap(find.text('02'));
    await esperar(tester);
    expect(find.text('A-02'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await esperar(tester);

    expect(find.text('Confirma tu reserva'), findsOneWidget);
    await tester.tap(find.text(r'Pagar ahora $9.000'));
    await esperar(tester);

    expect((reservas.creadas, reservas.pagos), (1, 1));
    expect(find.text('¡Tu reserva ha sido confirmada!'), findsOneWidget);
    expect(find.text('Rsv-000777'), findsOneWidget);
    expect(find.text('Zona A – Plaza A-02'), findsOneWidget);
  });

  testWidgets(
    'reservar y pagar después deja la reserva pendiente con opción de pagar',
    (tester) async {
      final reservas = NuevaReservaFalso();
      await _reservarDesdeElMapa(tester, reservas);
      await _elegirPlazaYContinuar(tester);

      await tester.tap(find.text('Reservar y pagar después'));
      await esperar(tester);
      expect(find.text('Reserva creada: falta el pago'), findsOneWidget);
      expect(reservas.pagos, 0);

      await tester.tap(find.text(r'Pagar $9.000'));
      await esperar(tester);
      expect(reservas.pagos, 1);
      expect(find.text('¡Tu reserva ha sido confirmada!'), findsOneWidget);
    },
  );

  testWidgets('si alguien toma la plaza, vuelve a la grilla y avisa', (
    tester,
  ) async {
    final reservas = NuevaReservaFalso()..conflictoAlCrear = true;
    await _reservarDesdeElMapa(tester, reservas);
    await _elegirPlazaYContinuar(tester);

    await tester.tap(find.text(r'Pagar ahora $9.000'));
    await esperar(tester);
    expect(find.text('Selecciona tu Plaza'), findsOneWidget);
    expect(
      find.text('El espacio ya está reservado en ese horario'),
      findsOneWidget,
    );
    expect(find.text('Toca una plaza verde'), findsOneWidget);
  });

  testWidgets('atrás regresa al paso anterior', (tester) async {
    await _reservarDesdeElMapa(tester, NuevaReservaFalso());
    await _elegirPlazaYContinuar(tester);
    expect(find.text('Confirma tu reserva'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await esperar(tester);
    expect(find.text('Selecciona tu Plaza'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await esperar(tester);
    expect(find.text('Nueva Reserva'), findsOneWidget);
  });
}

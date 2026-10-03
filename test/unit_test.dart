import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkingpro/core/network/api_exception.dart';
import 'package:parkingpro/core/utils/formatos.dart';
import 'package:parkingpro/features/reservas/domain/reserva.dart';

DioException _respuesta(int status, dynamic data) {
  final opciones = RequestOptions(path: '/x');
  return DioException(
    requestOptions: opciones,
    response: Response(
      requestOptions: opciones,
      statusCode: status,
      data: data,
    ),
  );
}

void main() {
  group('ApiException', () {
    test('usa el detail de FastAPI', () {
      final e = ApiException.desde(
        _respuesta(409, {'detail': 'El email ya está registrado'}),
      );
      expect(e.mensaje, 'El email ya está registrado');
      expect(e.statusCode, 409);
    });

    test('resume errores de validación', () {
      final e = ApiException.desde(
        _respuesta(422, {
          'detail': [
            {
              'loc': ['body', 'password'],
              'msg': 'String should have at least 8 characters',
            },
          ],
        }),
      );
      expect(e.mensaje, 'password: String should have at least 8 characters');
    });

    test('sin respuesta = sin conexión', () {
      final e = ApiException.desde(
        DioException(requestOptions: RequestOptions(path: '/x')),
      );
      expect(e.mensaje, contains('No hay conexión'));
    });
  });

  test('formatos', () {
    expect(pesos(1245000), r'$1.245.000');
    expect(pesos(4500.0), r'$4.500');
    expect(
      cronometro(const Duration(hours: 2, minutes: 35, seconds: 45)),
      '02:35:45',
    );
  });

  test('Reserva desde el JSON de la API', () {
    final r = Reserva.fromJson({
      'id': 'r1',
      'codigo': 'Rsv-000123',
      'estado': 'confirmada',
      'fecha_inicio': '2026-10-01T15:00:00+00:00',
      'fecha_fin': '2026-10-01T17:00:00+00:00',
      'total': 9000.0,
      'total_pagado': 0.0,
      'saldo': 9000.0,
      'tarifa_aplicada': {'nombre': 'Carro', 'valor_hora': 4500.0},
      'sede_id': 's1',
      'espacio_id': 'e1',
      'zona': 'Zona A',
      'espacio_codigo': 'A-12',
      'sesion': {
        'hora_entrada': '2026-10-01T15:05:00+00:00',
        'estado': 'activa',
      },
    });
    expect(r.ubicacion, 'Zona A – Plaza A-12');
    expect(r.sesion!.activa, isTrue);
    expect(r.fechaInicio.isUtc, isTrue);
  });
}

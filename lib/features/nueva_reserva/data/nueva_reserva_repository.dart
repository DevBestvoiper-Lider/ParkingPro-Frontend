import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../reservas/domain/reserva.dart';
import '../domain/modelos.dart';

class NuevaReservaRepository {
  NuevaReservaRepository(this._dio);

  final Dio _dio;

  Future<T> _llamar<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  Future<List<Zona>> zonas(String sedeId) => _llamar(() async {
    final res = await _dio.get<List<dynamic>>(
      '/espacios/zonas',
      queryParameters: {'sede_id': sedeId},
    );
    return [
      for (final z in res.data!) Zona.fromJson(z as Map<String, dynamic>),
    ];
  });

  Future<List<Tarifa>> tarifas(String sedeId, String tipoVehiculo) =>
      _llamar(() async {
        final res = await _dio.get<List<dynamic>>(
          '/tarifas',
          queryParameters: {'sede_id': sedeId, 'tipo_vehiculo': tipoVehiculo},
        );
        final lista = [
          for (final t in res.data!) Tarifa.fromJson(t as Map<String, dynamic>),
        ];
        return lista..sort((a, b) => a.valorHora.compareTo(b.valorHora));
      });

  Future<List<Plaza>> plazas({
    required String sedeId,
    required DateTime inicio,
    required DateTime fin,
    required String tipo,
    String? zona,
  }) => _llamar(() async {
    final res = await _dio.get<List<dynamic>>(
      '/espacios/plazas',
      queryParameters: {
        'sede_id': sedeId,
        'fecha_inicio': inicio.toUtc().toIso8601String(),
        'fecha_fin': fin.toUtc().toIso8601String(),
        'tipo': tipo,
        'zona': ?zona,
      },
    );
    return [
      for (final p in res.data!) Plaza.fromJson(p as Map<String, dynamic>),
    ];
  });

  /// % de descuento del plan Afiliado (0 si el usuario está en el plan por uso).
  Future<int> descuentoPlan() => _llamar(() async {
    final res = await _dio.get<dynamic>('/suscripciones/mia');
    final data = res.data;
    return data is Map ? (data['descuento_pct'] as int? ?? 0) : 0;
  });

  Future<Reserva> crear({
    required String sedeId,
    required String espacioId,
    required String tarifaId,
    required String vehiculoId,
    required DateTime inicio,
    required DateTime fin,
  }) => _llamar(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/reservas',
      data: {
        'sede_id': sedeId,
        'espacio_id': espacioId,
        'tarifa_id': tarifaId,
        'vehiculo_id': vehiculoId,
        'fecha_inicio': inicio.toUtc().toIso8601String(),
        'fecha_fin': fin.toUtc().toIso8601String(),
      },
    );
    return Reserva.fromJson(res.data!);
  });

  /// Pre-pago desde la app. Al cubrir el total, la API confirma la reserva.
  Future<Reserva> pagar(String reservaId, double monto) => _llamar(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/reservas/$reservaId/pagos',
      data: {'monto': monto, 'metodo_pago': 'app'},
    );
    return Reserva.fromJson(res.data!);
  });
}

final nuevaReservaRepositoryProvider = Provider<NuevaReservaRepository>(
  (ref) => NuevaReservaRepository(ref.watch(dioProvider)),
);

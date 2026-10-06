import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/reserva.dart';

class ReservasRepository {
  ReservasRepository(this._dio);

  final Dio _dio;

  Future<ResumenUsuario> resumen() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/reservas/mias/resumen',
      );
      return ResumenUsuario.fromJson(res.data!);
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  /// `estado` se repite en la query: `?estado=pendiente&estado=confirmada`.
  Future<List<Reserva>> mias(List<String> estados) async {
    try {
      final filtro = estados
          .map((e) => 'estado=${Uri.encodeQueryComponent(e)}')
          .join('&');
      final res = await _dio.get<List<dynamic>>('/reservas/mias?$filtro');
      return [
        for (final item in res.data ?? const [])
          Reserva.fromJson(item as Map<String, dynamic>),
      ];
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  /// Cubre el saldo desde la app. Al pagarlo completo, la API confirma la reserva.
  Future<Reserva> pagar(String reservaId, double monto) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/reservas/$reservaId/pagos',
        data: {'monto': monto, 'metodo_pago': 'app'},
      );
      return Reserva.fromJson(res.data!);
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  Future<Reserva> cancelar(String reservaId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/reservas/$reservaId/cancelar',
      );
      return Reserva.fromJson(res.data!);
    } catch (e) {
      throw ApiException.desde(e);
    }
  }
}

final reservasRepositoryProvider = Provider<ReservasRepository>(
  (ref) => ReservasRepository(ref.watch(dioProvider)),
);

/// Datos de la pantalla de Inicio. `ref.invalidate(resumenProvider)` para recargar.
final resumenProvider = FutureProvider.autoDispose<ResumenUsuario>(
  (ref) => ref.watch(reservasRepositoryProvider).resumen(),
);

const estadosPorPestana = {
  'proximas': ['pendiente', 'confirmada'],
  'completadas': ['completada'],
  'canceladas': ['cancelada'],
};

final misReservasProvider = FutureProvider.autoDispose
    .family<List<Reserva>, String>(
      (ref, pestana) => ref
          .watch(reservasRepositoryProvider)
          .mias(estadosPorPestana[pestana] ?? estadosPorPestana['proximas']!),
    );

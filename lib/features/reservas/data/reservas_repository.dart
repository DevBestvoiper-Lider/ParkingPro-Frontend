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
}

final reservasRepositoryProvider = Provider<ReservasRepository>(
  (ref) => ReservasRepository(ref.watch(dioProvider)),
);

/// Datos de la pantalla de Inicio. `ref.invalidate(resumenProvider)` para recargar.
final resumenProvider = FutureProvider.autoDispose<ResumenUsuario>(
  (ref) => ref.watch(reservasRepositoryProvider).resumen(),
);

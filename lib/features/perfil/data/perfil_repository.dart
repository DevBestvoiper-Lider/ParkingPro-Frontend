import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/usuario.dart';

class PerfilRepository {
  PerfilRepository(this._dio);

  final Dio _dio;

  Future<Usuario> agregarVehiculo({
    required String placa,
    String? marca,
    String? modelo,
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/usuarios/me/vehiculos',
        data: {
          'placa': placa,
          if (marca != null && marca.isNotEmpty) 'marca': marca,
          if (modelo != null && modelo.isNotEmpty) 'modelo': modelo,
          if (color != null && color.isNotEmpty) 'color': color,
        },
      );
      return Usuario.fromJson(res.data!);
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  Future<Usuario> eliminarVehiculo(String vehiculoId) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/usuarios/me/vehiculos/$vehiculoId',
      );
      return Usuario.fromJson(res.data!);
    } catch (e) {
      throw ApiException.desde(e);
    }
  }
}

final perfilRepositoryProvider = Provider<PerfilRepository>(
  (ref) => PerfilRepository(ref.watch(dioProvider)),
);

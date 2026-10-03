import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/filtros_mapa.dart';
import '../domain/sede_cercana.dart';

class MapaRepository {
  MapaRepository(this._dio);

  final Dio _dio;

  Future<List<SedeCercana>> cercanos(
    LatLng ubicacion,
    FiltrosMapa filtros,
  ) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/parqueaderos/cercanos',
        queryParameters: {
          'latitud': ubicacion.latitude,
          'longitud': ubicacion.longitude,
          'radio_km': filtros.radioKm,
          'tipo': filtros.tipo,
          if (filtros.texto.trim().isNotEmpty) 'q': filtros.texto.trim(),
        },
      );
      return [
        for (final s in res.data!)
          SedeCercana.fromJson(s as Map<String, dynamic>),
      ];
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  /// Avisa que este usuario/dispositivo está viendo la sede. Devuelve cuántos la están viendo.
  Future<int> marcarInteres(
    String sedeId, {
    required String dispositivoId,
    String? espacioId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/sedes/$sedeId/interes',
        data: {'dispositivo_id': dispositivoId, 'espacio_id': ?espacioId},
      );
      return res.data!['viendo'] as int;
    } catch (e) {
      throw ApiException.desde(e);
    }
  }
}

final mapaRepositoryProvider = Provider<MapaRepository>(
  (ref) => MapaRepository(ref.watch(dioProvider)),
);

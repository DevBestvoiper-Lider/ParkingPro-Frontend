import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/network/api_exception.dart';
import '../domain/ruta.dart';

/// Traza la ruta en carro con OSRM. No usa la API de ParkingPro.
class RutaRepository {
  RutaRepository(this._dio);

  final Dio _dio;

  Future<Ruta> trazar(LatLng desde, LatLng hasta) async {
    try {
      final camino =
          '${desde.longitude},${desde.latitude};${hasta.longitude},${hasta.latitude}';
      final res = await _dio.get<Map<String, dynamic>>(
        '/route/v1/driving/$camino',
        queryParameters: const {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'true',
        },
      );
      final data = res.data!;
      if (data['code'] != 'Ok') {
        throw ApiException('No hay una ruta en carro hasta ese parqueadero');
      }
      final ruta = (data['routes'] as List).first as Map<String, dynamic>;
      final coords = (ruta['geometry'] as Map)['coordinates'] as List;
      final puntos = [
        for (final c in coords)
          LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      final steps = ((ruta['legs'] as List).first as Map)['steps'] as List;
      return Ruta(
        puntos: puntos,
        distanciaMetros: (ruta['distance'] as num).toDouble(),
        duracionSegundos: (ruta['duration'] as num).toDouble(),
        pasos: [
          for (final paso in steps)
            if (paso is Map<String, dynamic>) _paso(paso),
        ],
      );
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  PasoRuta _paso(Map<String, dynamic> paso) {
    final maniobra = paso['maneuver'] as Map<String, dynamic>? ?? const {};
    final lugar = (maniobra['location'] as List?) ?? const [0, 0];
    return PasoRuta(
      instruccion: instruccionDeManiobra(
        maniobra['type'] as String? ?? '',
        maniobra['modifier'] as String?,
        paso['name'] as String? ?? '',
      ),
      distanciaMetros: (paso['distance'] as num?)?.toDouble() ?? 0,
      punto: LatLng(
        (lugar[1] as num).toDouble(),
        (lugar[0] as num).toDouble(),
      ),
    );
  }
}

final rutaRepositoryProvider = Provider<RutaRepository>(
  (ref) => RutaRepository(
    Dio(
      BaseOptions(
        baseUrl: 'https://router.project-osrm.org',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    ),
  ),
);

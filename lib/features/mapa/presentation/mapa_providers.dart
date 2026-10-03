import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/mapa_repository.dart';
import '../domain/filtros_mapa.dart';
import '../domain/sede_cercana.dart';

/// Centro de Cartagena: se usa si no hay permiso de ubicación o el GPS no responde.
const centroCartagena = LatLng(10.4236, -75.5478);

class Ubicacion {
  const Ubicacion(this.punto, {required this.real});

  final LatLng punto;

  /// false = no es la posición del usuario sino el centro de Cartagena.
  final bool real;
}

final ubicacionProvider = FutureProvider<Ubicacion>((ref) async {
  const respaldo = Ubicacion(centroCartagena, real: false);
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return respaldo;
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return respaldo;
    }
    final posicion = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return Ubicacion(LatLng(posicion.latitude, posicion.longitude), real: true);
  } catch (_) {
    return respaldo;
  }
});

class FiltrosMapaNotifier extends Notifier<FiltrosMapa> {
  @override
  FiltrosMapa build() => const FiltrosMapa();

  void actualizar(FiltrosMapa filtros) => state = filtros;
  void buscar(String texto) => state = state.copyWith(texto: texto);
}

final filtrosMapaProvider = NotifierProvider<FiltrosMapaNotifier, FiltrosMapa>(
  FiltrosMapaNotifier.new,
);

final sedesCercanasProvider = FutureProvider.autoDispose<List<SedeCercana>>((
  ref,
) async {
  final ubicacion = await ref.watch(ubicacionProvider.future);
  final filtros = ref.watch(filtrosMapaProvider);
  return ref.watch(mapaRepositoryProvider).cercanos(ubicacion.punto, filtros);
});

class SedeSeleccionadaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void seleccionar(String? sedeId) => state = sedeId;
}

final sedeSeleccionadaProvider =
    NotifierProvider<SedeSeleccionadaNotifier, String?>(
      SedeSeleccionadaNotifier.new,
    );

/// Los tests lo apagan para no descargar mosaicos de OpenStreetMap.
final mostrarMosaicosProvider = Provider<bool>((ref) => true);

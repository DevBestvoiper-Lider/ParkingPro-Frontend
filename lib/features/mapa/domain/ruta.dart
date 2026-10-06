import 'package:latlong2/latlong.dart';

class PasoRuta {
  const PasoRuta({
    required this.instruccion,
    required this.distanciaMetros,
    required this.punto,
  });

  final String instruccion;
  final double distanciaMetros;
  final LatLng punto;
}

/// Recorrido en carro desde el usuario hasta el parqueadero.
class Ruta {
  const Ruta({
    required this.puntos,
    required this.distanciaMetros,
    required this.duracionSegundos,
    required this.pasos,
  });

  final List<LatLng> puntos;
  final double distanciaMetros;
  final double duracionSegundos;
  final List<PasoRuta> pasos;

  String get resumen {
    final minutos = (duracionSegundos / 60).round().clamp(1, 9999);
    final tiempo = minutos < 60
        ? '$minutos min'
        : '${minutos ~/ 60} h ${minutos % 60} min';
    final distancia = distanciaMetros < 1000
        ? '${distanciaMetros.round()} m'
        : '${(distanciaMetros / 1000).toStringAsFixed(1)} km';
    return '$tiempo · $distancia';
  }
}

String instruccionDeManiobra(String tipo, String? modificador, String nombre) {
  final via = nombre.trim().isEmpty ? '' : ' por ${nombre.trim()}';
  return switch ((tipo, modificador)) {
    ('depart', _) => 'Empieza$via',
    ('arrive', _) => 'Llegas al parqueadero',
    ('turn', 'left') || ('turn', 'sharp left') => 'Gira a la izquierda$via',
    ('turn', 'right') || ('turn', 'sharp right') => 'Gira a la derecha$via',
    ('turn', 'slight left') || ('end of road', 'left') => 'Mantente a la izquierda$via',
    ('turn', 'slight right') || ('end of road', 'right') => 'Mantente a la derecha$via',
    ('turn', 'uturn') || ('turn', 'uturn left') || ('turn', 'uturn right') =>
      'Da la vuelta$via',
    ('roundabout', _) || ('rotary', _) || ('exit roundabout', _) =>
      'Toma la glorieta$via',
    ('fork', 'left') => 'En el desvío, toma la izquierda$via',
    ('fork', 'right') => 'En el desvío, toma la derecha$via',
    ('merge', _) => 'Incorpórate$via',
    _ => via.isEmpty ? 'Continúa recto' : 'Continúa$via',
  };
}

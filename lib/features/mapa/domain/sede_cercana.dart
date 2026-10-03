import 'package:latlong2/latlong.dart';

/// Una sede en el mapa, con su distancia, precio desde y cupos libres en la próxima hora.
class SedeCercana {
  const SedeCercana({
    required this.sedeId,
    required this.parqueaderoId,
    required this.parqueaderoNombre,
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.punto,
    required this.distanciaKm,
    required this.espaciosLibres,
    required this.espaciosTotal,
    required this.interesados,
    this.precioHoraDesde,
    this.telefono,
  });

  final String sedeId;
  final String parqueaderoId;
  final String parqueaderoNombre;
  final String nombre;
  final String direccion;
  final String ciudad;
  final LatLng punto;
  final double distanciaKm;
  final int espaciosLibres;
  final int espaciosTotal;
  final int interesados;
  final double? precioHoraDesde;
  final String? telefono;

  factory SedeCercana.fromJson(Map<String, dynamic> json) => SedeCercana(
    sedeId: json['sede_id'] as String,
    parqueaderoId: json['parqueadero_id'] as String,
    parqueaderoNombre: json['parqueadero_nombre'] as String,
    nombre: json['nombre'] as String,
    direccion: json['direccion'] as String,
    ciudad: json['ciudad'] as String,
    punto: LatLng(
      (json['latitud'] as num).toDouble(),
      (json['longitud'] as num).toDouble(),
    ),
    distanciaKm: (json['distancia_km'] as num).toDouble(),
    espaciosLibres: json['espacios_libres'] as int,
    espaciosTotal: json['espacios_total'] as int? ?? 0,
    interesados: json['interesados'] as int? ?? 0,
    precioHoraDesde: (json['precio_hora_desde'] as num?)?.toDouble(),
    telefono: json['telefono'] as String?,
  );

  /// Fracción ocupada (0 a 1) para la barra de la lista.
  double get ocupacion =>
      espaciosTotal == 0 ? 1 : 1 - espaciosLibres / espaciosTotal;

  Disponibilidad get disponibilidad {
    if (espaciosLibres == 0) return Disponibilidad.llena;
    if (espaciosTotal > 0 && espaciosLibres / espaciosTotal < 0.3) {
      return Disponibilidad.pocos;
    }
    return Disponibilidad.amplia;
  }

  /// "850 m" o "2.6 km"
  String get distanciaTexto => distanciaKm < 1
      ? '${(distanciaKm * 1000).round()} m'
      : '${distanciaKm.toStringAsFixed(1)} km';
}

enum Disponibilidad { amplia, pocos, llena }

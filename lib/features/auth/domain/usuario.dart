class Vehiculo {
  const Vehiculo({
    required this.id,
    required this.placa,
    this.marca,
    this.modelo,
    this.color,
  });

  final String id;
  final String placa;
  final String? marca;
  final String? modelo;
  final String? color;

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
    id: json['id'] as String,
    placa: json['placa'] as String,
    marca: json['marca'] as String?,
    modelo: json['modelo'] as String?,
    color: json['color'] as String?,
  );

  /// "Mazda 3 · Rojo"
  String get descripcion => [
    marca,
    modelo,
    color,
  ].where((t) => t != null && t.isNotEmpty).join(' · ');
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.vehiculos = const [],
  });

  final String id;
  final String nombre;
  final String email;
  final String? telefono;
  final List<Vehiculo> vehiculos;

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    email: json['email'] as String,
    telefono: json['telefono'] as String?,
    vehiculos: [
      for (final v in (json['vehiculos'] as List? ?? const []))
        Vehiculo.fromJson(v as Map<String, dynamic>),
    ],
  );

  String get primerNombre => nombre.split(' ').first;
}

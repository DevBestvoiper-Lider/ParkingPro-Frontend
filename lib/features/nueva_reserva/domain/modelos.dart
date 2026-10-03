import 'package:flutter/material.dart';

class Tarifa {
  const Tarifa({
    required this.id,
    required this.nombre,
    required this.tipoVehiculo,
    required this.valorHora,
  });

  final String id;
  final String nombre;
  final String tipoVehiculo; // carro | moto
  final double valorHora;

  factory Tarifa.fromJson(Map<String, dynamic> json) => Tarifa(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    tipoVehiculo: json['tipo_vehiculo'] as String,
    valorHora: (json['valor_hora'] as num).toDouble(),
  );
}

class Zona {
  const Zona({required this.nombre, required this.plazas});

  final String nombre;
  final int plazas;

  factory Zona.fromJson(Map<String, dynamic> json) =>
      Zona(nombre: json['zona'] as String, plazas: json['plazas'] as int);
}

/// Plaza con su estado para el horario consultado.
class Plaza {
  const Plaza({
    required this.id,
    required this.codigo,
    required this.tipo,
    required this.estadoHorario,
    this.zona,
    this.interesados = 0,
  });

  final String id;
  final String codigo;
  final String tipo; // carro | moto | discapacitado
  final String
  estadoHorario; // disponible | ocupada | reservada | mantenimiento
  final String? zona;
  final int interesados;

  factory Plaza.fromJson(Map<String, dynamic> json) => Plaza(
    id: json['id'] as String,
    codigo: json['codigo'] as String,
    tipo: json['tipo'] as String,
    estadoHorario: json['estado_horario'] as String,
    zona: json['zona'] as String?,
    interesados: json['interesados'] as int? ?? 0,
  );

  bool get disponible => estadoHorario == 'disponible';

  /// "A-12" -> "12" (dentro de su zona basta el número, como en el mockup).
  String get numero => codigo.contains('-') ? codigo.split('-').last : codigo;
}

/// Tarifa que aplica a cada tipo de espacio (igual que en la API).
const tarifaPorTipoEspacio = {
  'carro': 'carro',
  'moto': 'moto',
  'discapacitado': 'carro',
};

/// Cobro por hora o fracción, mínimo una hora (misma regla que la API).
double estimarTotal({
  required double valorHora,
  required DateTime inicio,
  required DateTime fin,
  int descuentoPct = 0,
}) {
  final minutos = fin.difference(inicio).inMinutes;
  final horas = minutos <= 0 ? 1 : (minutos / 60).ceil();
  final valor = valorHora * (100 - descuentoPct) / 100;
  return double.parse((valor * horas).toStringAsFixed(2));
}

DateTime combinar(DateTime fecha, TimeOfDay hora) =>
    DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);

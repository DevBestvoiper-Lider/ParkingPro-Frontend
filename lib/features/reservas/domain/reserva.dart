class SesionParqueo {
  const SesionParqueo({
    required this.estado,
    this.horaEntrada,
    this.horaSalida,
  });

  final String estado; // activa | finalizada
  final DateTime? horaEntrada;
  final DateTime? horaSalida;

  factory SesionParqueo.fromJson(Map<String, dynamic> json) => SesionParqueo(
    estado: json['estado'] as String,
    horaEntrada: _fecha(json['hora_entrada']),
    horaSalida: _fecha(json['hora_salida']),
  );

  bool get activa => estado == 'activa';
}

class Reserva {
  const Reserva({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.total,
    required this.totalPagado,
    required this.saldo,
    required this.valorHora,
    required this.sedeId,
    required this.espacioId,
    this.sesion,
    this.sedeNombre,
    this.parqueaderoNombre,
    this.zona,
    this.espacioCodigo,
    this.placa,
  });

  final String id;
  final String codigo;
  final String estado; // pendiente | confirmada | cancelada | completada
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double total;
  final double totalPagado;
  final double saldo;
  final double valorHora;
  final String sedeId;
  final String espacioId;
  final SesionParqueo? sesion;
  final String? sedeNombre;
  final String? parqueaderoNombre;
  final String? zona;
  final String? espacioCodigo;
  final String? placa;

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as String,
    codigo: json['codigo'] as String? ?? '',
    estado: json['estado'] as String,
    fechaInicio: _fecha(json['fecha_inicio'])!,
    fechaFin: _fecha(json['fecha_fin'])!,
    total: (json['total'] as num).toDouble(),
    totalPagado: (json['total_pagado'] as num).toDouble(),
    saldo: (json['saldo'] as num).toDouble(),
    valorHora: ((json['tarifa_aplicada'] as Map)['valor_hora'] as num)
        .toDouble(),
    sedeId: json['sede_id'] as String,
    espacioId: json['espacio_id'] as String,
    sesion: json['sesion'] == null
        ? null
        : SesionParqueo.fromJson(json['sesion'] as Map<String, dynamic>),
    sedeNombre: json['sede_nombre'] as String?,
    parqueaderoNombre: json['parqueadero_nombre'] as String?,
    zona: json['zona'] as String?,
    espacioCodigo: json['espacio_codigo'] as String?,
    placa: json['placa'] as String?,
  );

  /// "Zona A – Plaza A-12"
  String get ubicacion {
    final plaza = espacioCodigo == null ? null : 'Plaza $espacioCodigo';
    return [zona, plaza].whereType<String>().join(' – ');
  }
}

class ResumenUsuario {
  const ResumenUsuario({
    required this.reservasProximas,
    required this.vehiculos,
    required this.plan,
    required this.notificacionesNoLeidas,
    this.sesionActiva,
  });

  final int reservasProximas;
  final int vehiculos;
  final String plan; // por_uso | afiliado
  final int notificacionesNoLeidas;
  final Reserva? sesionActiva;

  bool get esAfiliado => plan == 'afiliado';

  factory ResumenUsuario.fromJson(Map<String, dynamic> json) => ResumenUsuario(
    reservasProximas: json['reservas_proximas'] as int,
    vehiculos: json['vehiculos'] as int,
    plan: json['plan'] as String,
    notificacionesNoLeidas: json['notificaciones_no_leidas'] as int,
    sesionActiva: json['sesion_activa'] == null
        ? null
        : Reserva.fromJson(json['sesion_activa'] as Map<String, dynamic>),
  );
}

DateTime? _fecha(dynamic valor) =>
    valor == null ? null : DateTime.parse(valor as String);

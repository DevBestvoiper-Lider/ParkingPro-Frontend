import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mapa/data/mapa_repository.dart';
import '../../mapa/domain/filtros_mapa.dart';
import '../../mapa/domain/sede_cercana.dart';
import '../../mapa/presentation/mapa_providers.dart';
import '../data/nueva_reserva_repository.dart';
import '../domain/modelos.dart';

/// Lo que el usuario va eligiendo en el flujo de reserva.
class BorradorReserva {
  const BorradorReserva({
    required this.fecha,
    required this.entrada,
    required this.salida,
    this.sede,
    this.tipoEspacio = 'carro',
    this.zona,
    this.vehiculoId,
    this.tarifa,
    this.plaza,
  });

  factory BorradorReserva.inicial(DateTime ahora) {
    // Entrada: el próximo cuarto de hora. Salida: dos horas después.
    final minutos = ((ahora.minute ~/ 15) + 1) * 15;
    final entrada = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      ahora.hour,
    ).add(Duration(minutes: minutos));
    final salida = entrada.add(const Duration(hours: 2));
    return BorradorReserva(
      fecha: DateTime(entrada.year, entrada.month, entrada.day),
      entrada: TimeOfDay.fromDateTime(entrada),
      salida: TimeOfDay.fromDateTime(salida),
    );
  }

  final DateTime fecha;
  final TimeOfDay entrada;
  final TimeOfDay salida;
  final SedeCercana? sede;
  final String tipoEspacio;
  final String? zona; // null = todas
  final String? vehiculoId;
  final Tarifa? tarifa;
  final Plaza? plaza;

  DateTime get inicio => combinar(fecha, entrada);

  /// Si la salida es más temprano que la entrada, es al día siguiente.
  DateTime get fin {
    final f = combinar(fecha, salida);
    return f.isAfter(inicio) ? f : f.add(const Duration(days: 1));
  }

  Duration get duracion => fin.difference(inicio);

  BorradorReserva _con({
    DateTime? fecha,
    TimeOfDay? entrada,
    TimeOfDay? salida,
    SedeCercana? sede,
    String? tipoEspacio,
    String? vehiculoId,
    Tarifa? tarifa,
    bool limpiarZona = false,
    String? zona,
    bool limpiarTarifa = false,
    bool limpiarPlaza = true, // casi cualquier cambio invalida la plaza elegida
    Plaza? plaza,
  }) => BorradorReserva(
    fecha: fecha ?? this.fecha,
    entrada: entrada ?? this.entrada,
    salida: salida ?? this.salida,
    sede: sede ?? this.sede,
    tipoEspacio: tipoEspacio ?? this.tipoEspacio,
    vehiculoId: vehiculoId ?? this.vehiculoId,
    zona: limpiarZona ? zona : (zona ?? this.zona),
    tarifa: limpiarTarifa ? tarifa : (tarifa ?? this.tarifa),
    plaza: limpiarPlaza ? plaza : (plaza ?? this.plaza),
  );
}

class NuevaReservaController extends Notifier<BorradorReserva> {
  @override
  BorradorReserva build() => BorradorReserva.inicial(DateTime.now());

  void elegirSede(SedeCercana sede) {
    if (sede.sedeId == state.sede?.sedeId) return;
    state = state._con(sede: sede, limpiarZona: true, limpiarTarifa: true);
  }

  void elegirTipo(String tipo) =>
      state = state._con(tipoEspacio: tipo, limpiarTarifa: true);
  void elegirVehiculo(String vehiculoId) =>
      state = state._con(vehiculoId: vehiculoId, limpiarPlaza: false);
  void elegirFecha(DateTime fecha) => state = state._con(fecha: fecha);
  void elegirSalida(TimeOfDay salida) => state = state._con(salida: salida);
  void elegirZona(String? zona) =>
      state = state._con(limpiarZona: true, zona: zona);
  void elegirTarifa(Tarifa tarifa) =>
      state = state._con(tarifa: tarifa, limpiarPlaza: false);
  void elegirPlaza(Plaza? plaza) => state = state._con(plaza: plaza);

  /// Cambiar la entrada conserva la duración elegida.
  void elegirEntrada(TimeOfDay entrada) {
    final duracion = state.duracion;
    final nuevaEntrada = combinar(state.fecha, entrada);
    state = state._con(
      entrada: entrada,
      salida: TimeOfDay.fromDateTime(nuevaEntrada.add(duracion)),
    );
  }
}

final nuevaReservaProvider =
    NotifierProvider.autoDispose<NuevaReservaController, BorradorReserva>(
      NuevaReservaController.new,
    );

/// Sedes para elegir: las de la ciudad (hasta 50 km), ordenadas por cercanía.
final sedesParaReservarProvider = FutureProvider.autoDispose<List<SedeCercana>>(
  (ref) async {
    final ubicacion = await ref.watch(ubicacionProvider.future);
    final tipo = ref.watch(nuevaReservaProvider.select((b) => b.tipoEspacio));
    return ref
        .watch(mapaRepositoryProvider)
        .cercanos(ubicacion.punto, FiltrosMapa(tipo: tipo, radioKm: 50));
  },
);

final zonasProvider = FutureProvider.autoDispose.family<List<Zona>, String>(
  (ref, sedeId) => ref.watch(nuevaReservaRepositoryProvider).zonas(sedeId),
);

final tarifasProvider = FutureProvider.autoDispose
    .family<List<Tarifa>, (String, String)>(
      (ref, clave) =>
          ref.watch(nuevaReservaRepositoryProvider).tarifas(clave.$1, clave.$2),
    );

typedef ConsultaPlazas = ({
  String sedeId,
  DateTime inicio,
  DateTime fin,
  String tipo,
  String? zona,
});

final plazasProvider = FutureProvider.autoDispose
    .family<List<Plaza>, ConsultaPlazas>(
      (ref, c) => ref
          .watch(nuevaReservaRepositoryProvider)
          .plazas(
            sedeId: c.sedeId,
            inicio: c.inicio,
            fin: c.fin,
            tipo: c.tipo,
            zona: c.zona,
          ),
    );

final descuentoPlanProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(nuevaReservaRepositoryProvider).descuentoPlan(),
);

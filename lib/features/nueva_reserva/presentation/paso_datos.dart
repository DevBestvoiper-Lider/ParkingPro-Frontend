import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../mapa/domain/sede_cercana.dart';
import '../../mapa/presentation/widgets_mapa.dart';
import '../../perfil/presentation/agregar_vehiculo_sheet.dart';
import '../domain/modelos.dart';
import 'componentes.dart';
import 'nueva_reserva_providers.dart';

/// Paso 1 del mockup "Nueva Reserva": sede, vehículo, tipo, fecha, horas y zona.
class PasoDatos extends ConsumerWidget {
  const PasoDatos({super.key, required this.alContinuar});

  final VoidCallback alContinuar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(nuevaReservaProvider);
    final ctrl = ref.read(nuevaReservaProvider.notifier);
    final usuario = ref.watch(authControllerProvider).value?.usuario;
    final vehiculos = usuario?.vehiculos ?? const [];
    final vehiculoId = b.vehiculoId ?? vehiculos.firstOrNull?.id;
    final sede = b.sede;

    final tarifas = sede == null
        ? null
        : ref.watch(
            tarifasProvider((
              sede.sedeId,
              tarifaPorTipoEspacio[b.tipoEspacio]!,
            )),
          );
    final tarifa = b.tarifa ?? tarifas?.value?.firstOrNull;
    final zonas = sede == null ? null : ref.watch(zonasProvider(sede.sedeId));
    final descuento = ref.watch(descuentoPlanProvider).value ?? 0;
    final total = tarifa == null
        ? null
        : estimarTotal(
            valorHora: tarifa.valorHora,
            inicio: b.inicio,
            fin: b.fin,
            descuentoPct: descuento,
          );

    final problema = switch (true) {
      _ when sede == null => null,
      _ when vehiculos.isEmpty => 'Agrega un vehículo para reservar',
      _ when tarifas?.hasValue == true && tarifa == null =>
        'Esta sede no tiene tarifa para ${nombresTipoEspacio[b.tipoEspacio]!.toLowerCase()}',
      _ when !b.fin.isAfter(DateTime.now()) => 'La hora de salida ya pasó',
      _ => null,
    };
    final listo =
        sede != null &&
        vehiculoId != null &&
        tarifa != null &&
        problema == null;

    Future<void> elegirSede() async {
      final elegida = await showModalBottomSheet<SedeCercana>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _ElegirSede(),
      );
      if (elegida != null) ctrl.elegirSede(elegida);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              CampoSelector(
                etiqueta: 'Sede',
                valor: sede == null
                    ? 'Elige un parqueadero'
                    : '${sede.nombre} · ${sede.parqueaderoNombre}',
                vacio: sede == null,
                icono: Icons.place_outlined,
                alTocar: elegirSede,
              ),
              const SizedBox(height: 14),
              const _Etiqueta('Vehículo'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final v in vehiculos)
                    ChoiceChip(
                      avatar: const Icon(Icons.directions_car, size: 18),
                      label: Text(v.placa),
                      selected: v.id == vehiculoId,
                      onSelected: (_) => ctrl.elegirVehiculo(v.id),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar'),
                    onPressed: () async {
                      final nuevo = await agregarVehiculo(context);
                      if (nuevo != null) ctrl.elegirVehiculo(nuevo.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _Etiqueta('Tipo de espacio'),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'carro',
                    icon: Icon(Icons.directions_car),
                    label: Text('Carro'),
                  ),
                  ButtonSegment(
                    value: 'moto',
                    icon: Icon(Icons.two_wheeler),
                    label: Text('Moto'),
                  ),
                  ButtonSegment(
                    value: 'discapacitado',
                    icon: Icon(Icons.accessible),
                    label: Text('Discap.'),
                  ),
                ],
                selected: {b.tipoEspacio},
                onSelectionChanged: (s) => ctrl.elegirTipo(s.first),
              ),
              const SizedBox(height: 14),
              CampoSelector(
                etiqueta: 'Fecha',
                valor: DateFormat('EEEE d \'de\' MMMM', 'es').format(b.fecha),
                icono: Icons.calendar_month_outlined,
                alTocar: () async {
                  final hoy = DateUtils.dateOnly(DateTime.now());
                  final fecha = await showDatePicker(
                    context: context,
                    initialDate: b.fecha.isBefore(hoy) ? hoy : b.fecha,
                    firstDate: hoy,
                    lastDate: hoy.add(const Duration(days: 30)),
                  );
                  if (fecha != null) ctrl.elegirFecha(fecha);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CampoSelector(
                      etiqueta: 'Hora de entrada',
                      valor: hora(b.inicio),
                      icono: Icons.schedule,
                      alTocar: () async {
                        final h = await showTimePicker(
                          context: context,
                          initialTime: b.entrada,
                        );
                        if (h != null) ctrl.elegirEntrada(h);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CampoSelector(
                      etiqueta: 'Hora de salida',
                      valor: b.fin.day != b.inicio.day
                          ? '${hora(b.fin)} (+1 día)'
                          : hora(b.fin),
                      icono: Icons.schedule,
                      alTocar: () async {
                        final h = await showTimePicker(
                          context: context,
                          initialTime: b.salida,
                        );
                        if (h != null) ctrl.elegirSalida(h);
                      },
                    ),
                  ),
                ],
              ),
              if (zonas?.value case final lista? when lista.length > 1) ...[
                const SizedBox(height: 14),
                const _Etiqueta('Zona'),
                DropdownButtonFormField<String?>(
                  initialValue: b.zona,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas las zonas'),
                    ),
                    for (final z in lista)
                      DropdownMenuItem(
                        value: z.nombre,
                        child: Text('${z.nombre} (${z.plazas} plazas)'),
                      ),
                  ],
                  onChanged: ctrl.elegirZona,
                ),
              ],
              if (tarifas?.value case final lista? when lista.length > 1) ...[
                const SizedBox(height: 14),
                const _Etiqueta('Tarifa'),
                DropdownButtonFormField<String>(
                  initialValue: tarifa?.id,
                  items: [
                    for (final t in lista)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text('${t.nombre} · ${pesos(t.valorHora)}/h'),
                      ),
                  ],
                  onChanged: (id) =>
                      ctrl.elegirTarifa(lista.firstWhere((t) => t.id == id)),
                ),
              ],
              if (tarifas?.error case final error?) ...[
                const SizedBox(height: 14),
                MensajeError(ApiException.desde(error).mensaje),
              ],
              if (problema != null) ...[
                const SizedBox(height: 16),
                MensajeError(problema),
              ],
            ],
          ),
        ),
        PiePaso(
          izquierda: total == null
              ? const Text(
                  'Elige sede y horario',
                  style: TextStyle(color: AppColors.textoTenue),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${textoDuracion(b.duracion)} · ${tarifa!.nombre}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textoTenue,
                      ),
                    ),
                    Text(
                      'Total: ${pesos(total)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (descuento > 0)
                      Text(
                        'Incluye -$descuento% Plan Afiliado',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.exito,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
          boton: FilledButton(
            onPressed: listo
                ? () {
                    ctrl.elegirVehiculo(vehiculoId);
                    ctrl.elegirTarifa(tarifa);
                    alContinuar();
                  }
                : null,
            child: const Text('Buscar Disponibilidad'),
          ),
        ),
      ],
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      texto,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textoTenue,
      ),
    ),
  );
}

/// Pie fijo con resumen a la izquierda y botón a la derecha.
class PiePaso extends StatelessWidget {
  const PiePaso({super.key, required this.izquierda, required this.boton});

  final Widget izquierda;
  final Widget boton;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: izquierda),
          const SizedBox(width: 12),
          // Los botones del tema ocupan todo el ancho: dentro de una fila necesitan un ancho acotado.
          Expanded(flex: 4, child: boton),
        ],
      ),
    );
  }
}

class _ElegirSede extends ConsumerWidget {
  const _ElegirSede();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sedes = ref.watch(sedesParaReservarProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Elige un parqueadero',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Expanded(
            child: switch (sedes) {
              AsyncData(:final value) when value.isEmpty => const Center(
                child: Text('No hay parqueaderos disponibles cerca'),
              ),
              AsyncData(:final value) => ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = value[i];
                  return Card(
                    child: ListTile(
                      onTap: () => Navigator.pop(context, s),
                      title: Text(
                        s.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.parqueaderoNombre} · ${s.distanciaTexto}'),
                          const SizedBox(height: 6),
                          BarraDisponibilidad(sede: s),
                        ],
                      ),
                      trailing: PrecioHora(
                        valor: s.precioHoraDesde,
                        tamano: 14,
                      ),
                    ),
                  );
                },
              ),
              AsyncError(:final error) => Center(
                child: Text(ApiException.desde(error).mensaje),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

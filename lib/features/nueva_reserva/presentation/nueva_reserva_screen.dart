import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reservas/data/reservas_repository.dart';
import '../../reservas/domain/reserva.dart';
import '../data/nueva_reserva_repository.dart';
import '../domain/modelos.dart';
import 'componentes.dart';
import 'nueva_reserva_providers.dart';
import 'paso_datos.dart';
import 'paso_plaza.dart';

/// Flujo de 4 pasos: datos → plaza → resumen y pago → confirmación.
class NuevaReservaScreen extends ConsumerStatefulWidget {
  const NuevaReservaScreen({super.key, this.sedeId});

  /// Sede preseleccionada (al venir desde el mapa).
  final String? sedeId;

  @override
  ConsumerState<NuevaReservaScreen> createState() => _NuevaReservaScreenState();
}

class _NuevaReservaScreenState extends ConsumerState<NuevaReservaScreen> {
  int _paso = 0;
  Reserva? _reserva;

  @override
  void initState() {
    super.initState();
    if (widget.sedeId != null) {
      ref.listenManual(sedesParaReservarProvider, fireImmediately: true, (
        _,
        sedes,
      ) {
        final sede = sedes.value?.firstWhereOrNull(
          (s) => s.sedeId == widget.sedeId,
        );
        if (sede != null && ref.read(nuevaReservaProvider).sede == null) {
          ref.read(nuevaReservaProvider.notifier).elegirSede(sede);
        }
      });
    }
  }

  void _atras() {
    if (_paso == 0 || _paso == 3) {
      _salir();
    } else {
      setState(() => _paso--);
    }
  }

  void _salir() => context.canPop() ? context.pop() : context.go('/inicio');

  void _terminar(Reserva reserva) {
    ref.invalidate(resumenProvider); // Inicio muestra la nueva reserva
    setState(() {
      _reserva = reserva;
      _paso = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(nuevaReservaProvider);
    final (titulo, subtitulo) = switch (_paso) {
      0 => ('Nueva Reserva', null),
      1 => (
        'Selecciona tu Plaza',
        '${b.zona ?? 'Todas las zonas'} – ${hora(b.inicio)} a ${hora(b.fin)}',
      ),
      2 => ('Confirma tu reserva', null),
      _ => (
        _reserva?.estado == 'confirmada'
            ? 'Reserva Confirmada'
            : 'Reserva creada',
        null,
      ),
    };

    return PopScope(
      canPop: _paso == 0 || _paso == 3,
      onPopInvokedWithResult: (salio, _) {
        if (!salio) _atras();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _atras,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitulo != null)
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textoTenue,
                  ),
                ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(18),
            child: Progreso(paso: _paso),
          ),
        ),
        body: switch (_paso) {
          0 => PasoDatos(alContinuar: () => setState(() => _paso = 1)),
          1 => PasoPlaza(alContinuar: () => setState(() => _paso = 2)),
          2 => _PasoResumen(
            alTerminar: _terminar,
            alPerderPlaza: () => setState(() => _paso = 1),
          ),
          _ => _PasoConfirmacion(
            reserva: _reserva!,
            alPagar: (r) => setState(() => _reserva = r),
          ),
        },
      ),
    );
  }
}

/// Paso 3: resumen de lo elegido y pre-pago.
class _PasoResumen extends ConsumerStatefulWidget {
  const _PasoResumen({required this.alTerminar, required this.alPerderPlaza});

  final ValueChanged<Reserva> alTerminar;
  final VoidCallback alPerderPlaza;

  @override
  ConsumerState<_PasoResumen> createState() => _PasoResumenState();
}

class _PasoResumenState extends ConsumerState<_PasoResumen> {
  bool _enviando = false;
  String? _error;

  Future<void> _reservar({required bool pagarAhora}) async {
    final b = ref.read(nuevaReservaProvider);
    final repo = ref.read(nuevaReservaRepositoryProvider);
    setState(() {
      _enviando = true;
      _error = null;
    });
    Reserva? reserva;
    try {
      reserva = await repo.crear(
        sedeId: b.sede!.sedeId,
        espacioId: b.plaza!.id,
        tarifaId: b.tarifa!.id,
        vehiculoId: b.vehiculoId!,
        inicio: b.inicio,
        fin: b.fin,
      );
      if (pagarAhora) reserva = await repo.pagar(reserva.id, reserva.saldo);
      widget.alTerminar(reserva);
    } on ApiException catch (e) {
      if (reserva != null) {
        // Se creó pero falló el pago: la confirmación ofrece reintentar.
        widget.alTerminar(reserva);
        return;
      }
      if (e.statusCode == 409 && mounted) {
        // Alguien tomó la plaza (o es hora pico): volver a la grilla.
        ref.read(nuevaReservaProvider.notifier).elegirPlaza(null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje)));
        widget.alPerderPlaza();
        return;
      }
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = ref.watch(nuevaReservaProvider);
    final descuento = ref.watch(descuentoPlanProvider).value ?? 0;
    final vehiculo = ref
        .watch(authControllerProvider)
        .value
        ?.usuario
        ?.vehiculos
        .firstWhereOrNull((v) => v.id == b.vehiculoId);
    final total = estimarTotal(
      valorHora: b.tarifa!.valorHora,
      inicio: b.inicio,
      fin: b.fin,
      descuentoPct: descuento,
    );
    final minutosParaPagar = descuento > 0 ? 60 : 15;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                FilaDato('Sede', '${b.sede!.nombre}\n${b.sede!.direccion}'),
                FilaDato(
                  'Plaza',
                  [
                    b.plaza!.zona,
                    'Plaza ${b.plaza!.codigo}',
                  ].whereType<String>().join(' – '),
                ),
                FilaDato('Vehículo', vehiculo?.placa ?? ''),
                FilaDato('Entrada', fechaHora(b.inicio)),
                FilaDato('Salida', fechaHora(b.fin)),
                FilaDato('Duración', textoDuracion(b.duracion)),
                FilaDato(
                  'Tarifa',
                  '${b.tarifa!.nombre} · ${pesos(b.tarifa!.valorHora)}/h',
                ),
                if (descuento > 0) FilaDato('Plan Afiliado', '-$descuento%'),
                FilaDato(
                  'Total estimado',
                  pesos(total),
                  resaltar: true,
                  ultima: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primario.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primario.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'Paga ahora para asegurar tu plaza. Si eliges pagar después, tienes $minutosParaPagar minutos; '
            'si no, la reserva se cancela. Se cobra por hora o fracción: si sales antes, pagas menos.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textoSecundario,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          MensajeError(_error!),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _enviando ? null : () => _reservar(pagarAhora: true),
          icon: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.phone_iphone),
          label: Text('Pagar ahora ${pesos(total)}'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: _enviando ? null : () => _reservar(pagarAhora: false),
          child: const Text('Reservar y pagar después'),
        ),
      ],
    );
  }
}

/// Paso 4: confirmación con el código de reserva (o pago pendiente).
class _PasoConfirmacion extends ConsumerStatefulWidget {
  const _PasoConfirmacion({required this.reserva, required this.alPagar});

  final Reserva reserva;
  final ValueChanged<Reserva> alPagar;

  @override
  ConsumerState<_PasoConfirmacion> createState() => _PasoConfirmacionState();
}

class _PasoConfirmacionState extends ConsumerState<_PasoConfirmacion> {
  bool _pagando = false;
  String? _error;

  Future<void> _pagar() async {
    setState(() {
      _pagando = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(nuevaReservaRepositoryProvider)
          .pagar(widget.reserva.id, widget.reserva.saldo);
      ref.invalidate(resumenProvider);
      widget.alPagar(r);
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _pagando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final confirmada = r.estado == 'confirmada';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: confirmada ? const Color(0xFF22C55E) : AppColors.alerta,
              shape: BoxShape.circle,
            ),
            child: Icon(
              confirmada ? Icons.check_rounded : Icons.hourglass_top_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          confirmada
              ? '¡Tu reserva ha sido confirmada!'
              : 'Reserva creada: falta el pago',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        if (!confirmada)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Paga para asegurar tu plaza antes de que la reserva venza.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoTenue),
            ),
          ),
        const SizedBox(height: 18),
        const Text(
          'Código de reserva:',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textoTenue),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borde),
            ),
            child: SelectableText(
              r.codigo,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primario,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilaDato('Sede', r.sedeNombre ?? ''),
        FilaDato('Plaza', r.ubicacion),
        FilaDato('Entrada', fechaHora(r.fechaInicio)),
        FilaDato('Salida', fechaHora(r.fechaFin)),
        FilaDato('Total estimado', pesos(r.total)),
        FilaDato(
          confirmada ? 'Pagado' : 'Por pagar',
          pesos(confirmada ? r.totalPagado : r.saldo),
          ultima: true,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          MensajeError(_error!),
        ],
        const SizedBox(height: 24),
        if (!confirmada) ...[
          FilledButton.icon(
            onPressed: _pagando ? null : _pagar,
            icon: _pagando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.phone_iphone),
            label: Text('Pagar ${pesos(r.saldo)}'),
          ),
          const SizedBox(height: 10),
        ],
        (confirmada ? FilledButton.new : OutlinedButton.new)(
          onPressed: () => context.go('/reservas'),
          child: const Text('Ver Mis Reservas'),
        ),
      ],
    );
  }
}

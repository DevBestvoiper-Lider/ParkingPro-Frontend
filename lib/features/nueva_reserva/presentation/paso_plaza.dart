import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/tiempo_real.dart';
import '../../../core/storage/dispositivo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../mapa/data/mapa_repository.dart';
import '../domain/modelos.dart';
import 'nueva_reserva_providers.dart';
import 'paso_datos.dart';

const colorPorEstado = {
  'disponible': Color(0xFF22C55E),
  'ocupada': Color(0xFFEF4444),
  'reservada': Color(0xFFF97316),
  'mantenimiento': Color(0xFF94A3B8),
};

/// Paso 2 del mockup "Selecciona tu Plaza". Se actualiza en vivo con los eventos de la sede.
class PasoPlaza extends ConsumerWidget {
  const PasoPlaza({super.key, required this.alContinuar});

  final VoidCallback alContinuar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(nuevaReservaProvider);
    final ctrl = ref.read(nuevaReservaProvider.notifier);
    final sede = b.sede!;
    final ConsultaPlazas consulta = (
      sedeId: sede.sedeId,
      inicio: b.inicio,
      fin: b.fin,
      tipo: b.tipoEspacio,
      zona: b.zona,
    );
    final plazas = ref.watch(plazasProvider(consulta));
    final descuento = ref.watch(descuentoPlanProvider).value ?? 0;

    // Tiempo real: si alguien reserva u ocupa una plaza, la grilla se recarga.
    ref.listen(eventosSedeProvider(sede.sedeId), (_, evento) {
      if (evento.hasValue && evento.value!['evento'] != 'interes') {
        ref.invalidate(plazasProvider(consulta));
      }
    });
    // Si la plaza elegida dejó de estar libre, se desmarca y se avisa.
    ref.listen(plazasProvider(consulta), (_, nuevas) {
      final elegida = ref.read(nuevaReservaProvider).plaza;
      final actual = nuevas.value?.firstWhereOrNull((p) => p.id == elegida?.id);
      if (elegida != null && actual != null && !actual.disponible) {
        ctrl.elegirPlaza(null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La plaza ${elegida.codigo} acaba de ser tomada. Elige otra.',
            ),
          ),
        );
      }
    });

    final total = estimarTotal(
      valorHora: b.tarifa!.valorHora,
      inicio: b.inicio,
      fin: b.fin,
      descuentoPct: descuento,
    );

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(plazasProvider(consulta).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _Leyenda(),
                const SizedBox(height: 14),
                switch (plazas) {
                  AsyncData(:final value) when value.isEmpty => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Esta sede no tiene plazas de este tipo.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AsyncData(:final value) => _Grilla(
                    plazas: value,
                    elegida: b.plaza,
                    alElegir: (plaza) {
                      ctrl.elegirPlaza(plaza);
                      _marcarInteres(ref, sede.sedeId, plaza.id);
                    },
                  ),
                  AsyncError(:final error) => MensajeError(
                    ApiException.desde(error).mensaje,
                  ),
                  _ => const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                },
                if (plazas.value case final lista?
                    when lista.isNotEmpty && !lista.any((p) => p.disponible))
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: MensajeError(
                      'No quedan plazas libres en ese horario. Prueba otra hora o zona.',
                    ),
                  ),
              ],
            ),
          ),
        ),
        PiePaso(
          izquierda: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                b.plaza == null ? 'Toca una plaza verde' : 'Plaza seleccionada',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textoTenue,
                ),
              ),
              if (b.plaza != null)
                Text(
                  b.plaza!.codigo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primario,
                  ),
                ),
              Text(
                'Total estimado: ${pesos(total)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          boton: FilledButton(
            onPressed: b.plaza == null ? null : alContinuar,
            child: const Text('Continuar'),
          ),
        ),
      ],
    );
  }

  Future<void> _marcarInteres(
    WidgetRef ref,
    String sedeId,
    String espacioId,
  ) async {
    try {
      final dispositivo = await ref.read(dispositivoIdProvider.future);
      await ref
          .read(mapaRepositoryProvider)
          .marcarInteres(
            sedeId,
            dispositivoId: dispositivo,
            espacioId: espacioId,
          );
    } catch (_) {
      // Informativo: no bloquea la reserva.
    }
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    const nombres = {
      'disponible': 'Disponible',
      'ocupada': 'Ocupada',
      'reservada': 'Reservada',
      'mantenimiento': 'Mantenimiento',
    };
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final MapEntry(key: estado, value: nombre) in nombres.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorPorEstado[estado],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textoTenue,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Grilla extends StatelessWidget {
  const _Grilla({
    required this.plazas,
    required this.elegida,
    required this.alElegir,
  });

  final List<Plaza> plazas;
  final Plaza? elegida;
  final ValueChanged<Plaza> alElegir;

  @override
  Widget build(BuildContext context) {
    final porZona = groupBy(plazas, (Plaza p) => p.zona ?? 'Sin zona');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final MapEntry(key: zona, value: lista) in porZona.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              '${zona.toUpperCase()} · ${lista.where((p) => p.disponible).length} libres de ${lista.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textoTenue,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: GridView.count(
              crossAxisCount: 5,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final plaza in lista)
                  _Casilla(
                    plaza: plaza,
                    elegida: plaza.id == elegida?.id,
                    alTocar: () => alElegir(plaza),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.plaza,
    required this.elegida,
    required this.alTocar,
  });

  final Plaza plaza;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = elegida
        ? AppColors.primario
        : colorPorEstado[plaza.estadoHorario] ?? AppColors.textoApagado;
    return Semantics(
      button: plaza.disponible,
      label: 'Plaza ${plaza.codigo}, ${plaza.estadoHorario}',
      child: Opacity(
        opacity: plaza.disponible || elegida ? 1 : 0.6,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: plaza.disponible ? alTocar : null,
            child: Container(
              decoration: elegida
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.azulProfundo,
                        width: 2.5,
                      ),
                    )
                  : null,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (plaza.tipo == 'discapacitado')
                          const Icon(
                            Icons.accessible,
                            size: 12,
                            color: Colors.white,
                          ),
                        Text(
                          plaza.numero,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cuántas personas miran esta plaza ahora mismo.
                  if (plaza.interesados > 0 && plaza.disponible && !elegida)
                    Positioned(
                      top: 2,
                      right: 3,
                      child: Text(
                        '👀${plaza.interesados}',
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

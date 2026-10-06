import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/reservas_repository.dart';
import '../domain/reserva.dart';

const _orden = ['proximas', 'completadas', 'canceladas'];

const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Pestañas Próximas, Completadas y Canceladas.
/// `?pestana=completadas` (el Historial de Inicio) abre Completadas.
class MisReservasScreen extends ConsumerStatefulWidget {
  const MisReservasScreen({super.key});

  @override
  ConsumerState<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends ConsumerState<MisReservasScreen> {
  int _indice = 0;
  String? _ocupada;
  String? _pestanaVista;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pedida = GoRouterState.of(context).uri.queryParameters['pestana'];
    if (pedida == _pestanaVista) return;
    _pestanaVista = pedida;
    final indice = _orden.indexOf(pedida ?? '');
    if (indice >= 0 && indice != _indice) setState(() => _indice = indice);
  }

  Future<void> _recargar() async {
    final pestana = _orden[_indice];
    ref.invalidate(misReservasProvider(pestana));
    ref.invalidate(resumenProvider);
    await ref.read(misReservasProvider(pestana).future);
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _pagar(Reserva reserva) async {
    setState(() => _ocupada = reserva.id);
    try {
      await ref.read(reservasRepositoryProvider).pagar(reserva.id, reserva.saldo);
      HapticFeedback.lightImpact();
      await _recargar();
      _avisar('Pago registrado');
    } catch (e) {
      _avisar(ApiException.desde(e).mensaje);
    } finally {
      if (mounted) setState(() => _ocupada = null);
    }
  }

  Future<void> _cancelar(Reserva reserva) async {
    final confirmar = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(reserva.codigo),
        message: const Text(
          'La plaza queda libre. Esta acción no se puede deshacer.',
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar reserva'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Volver'),
        ),
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _ocupada = reserva.id);
    try {
      await ref.read(reservasRepositoryProvider).cancelar(reserva.id);
      HapticFeedback.lightImpact();
      await _recargar();
      _avisar('Reserva cancelada');
    } catch (e) {
      _avisar(ApiException.desde(e).mensaje);
    } finally {
      if (mounted) setState(() => _ocupada = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(authControllerProvider).value;
    final invitado = sesion == null || sesion.esInvitado;
    final texto = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return CupertinoTheme(
      data: CupertinoThemeData(
        primaryColor: AppColors.primario,
        scaffoldBackgroundColor: AppColors.fondo,
        barBackgroundColor: AppColors.fondo,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primario,
          textStyle: TextStyle(fontFamily: texto, color: AppColors.texto, fontSize: 16),
          navLargeTitleTextStyle: TextStyle(
            fontFamily: texto,
            inherit: false,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.texto,
          ),
          navTitleTextStyle: TextStyle(
            fontFamily: texto,
            inherit: false,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.texto,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.fondo,
        body: invitado
            ? const _PedirCuenta()
            : CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _recargar),
                  const CupertinoSliverNavigationBar(
                    automaticallyImplyLeading: false,
                    largeTitle: Text('Mis reservas'),
                    border: null,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: CupertinoSlidingSegmentedControl<int>(
                        groupValue: _indice,
                        children: {
                          for (var i = 0; i < _orden.length; i++)
                            i: _Segmento(_etiqueta(_orden[i])),
                        },
                        onValueChanged: (valor) {
                          if (valor == null || _ocupada != null) return;
                          setState(() => _indice = valor);
                        },
                      ),
                    ),
                  ),
                  _Listado(
                    pestana: _orden[_indice],
                    ocupada: _ocupada,
                    alPagar: _pagar,
                    alCancelar: _cancelar,
                    alReintentar: _recargar,
                  ),
                ],
              ),
      ),
    );
  }
}

String _etiqueta(String pestana) => switch (pestana) {
  'completadas' => 'Completadas',
  'canceladas' => 'Canceladas',
  _ => 'Próximas',
};

class _Segmento extends StatelessWidget {
  const _Segmento(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Listado extends ConsumerWidget {
  const _Listado({
    required this.pestana,
    required this.ocupada,
    required this.alPagar,
    required this.alCancelar,
    required this.alReintentar,
  });

  final String pestana;
  final String? ocupada;
  final ValueChanged<Reserva> alPagar;
  final ValueChanged<Reserva> alCancelar;
  final Future<void> Function() alReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservas = ref.watch(misReservasProvider(pestana));
    return switch (reservas) {
      AsyncData(:final value) when value.isEmpty => SliverFillRemaining(
        hasScrollBody: false,
        child: _Vacio(pestana: pestana),
      ),
      AsyncData(:final value) => SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        sliver: SliverList.separated(
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _Tarjeta(
            reserva: value[i],
            ocupada: ocupada != null,
            trabajando: ocupada == value[i].id,
            alPagar: () => alPagar(value[i]),
            alCancelar: () => alCancelar(value[i]),
          ),
        ),
      ),
      AsyncError(:final error) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorConReintento(
          mensaje: ApiException.desde(error).mensaje,
          alReintentar: () => alReintentar(),
        ),
      ),
      _ => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CupertinoActivityIndicator(radius: 14)),
      ),
    };
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.reserva,
    required this.ocupada,
    required this.trabajando,
    required this.alPagar,
    required this.alCancelar,
  });

  final Reserva reserva;
  final bool ocupada;
  final bool trabajando;
  final VoidCallback alPagar;
  final VoidCallback alCancelar;

  @override
  Widget build(BuildContext context) {
    final pendiente = reserva.estado == 'pendiente';
    final lugar = reserva.sedeNombre ?? reserva.parqueaderoNombre ?? 'Parqueadero';
    final detalle = [
      if (reserva.ubicacion.isNotEmpty) reserva.ubicacion,
      if (reserva.placa != null) reserva.placa,
    ].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    lugar,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                _Estado(reserva.estado),
              ],
            ),
            if (detalle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                detalle,
                style: const TextStyle(fontSize: 14, color: AppColors.textoTenue),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _cuando(reserva.fechaInicio, reserva.fechaFin),
              style: const TextStyle(fontSize: 14, color: AppColors.textoSecundario),
            ),
            const SizedBox(height: 2),
            Text(
              reserva.codigo,
              style: const TextStyle(fontSize: 12, color: AppColors.textoApagado),
            ),
            const SizedBox(height: 12),
            _Monto(etiqueta: 'Total', valor: reserva.total),
            if (reserva.saldo > 0) ...[
              const SizedBox(height: 4),
              _Monto(etiqueta: 'Saldo', valor: reserva.saldo, destacado: true),
            ],
            if (pendiente) ...[
              const SizedBox(height: 8),
              if (trabajando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else ...[
                if (reserva.saldo > 0)
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: ocupada ? null : alPagar,
                      child: Text('Pagar ${pesos(reserva.saldo)}'),
                    ),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  onPressed: ocupada ? null : alCancelar,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Monto extends StatelessWidget {
  const _Monto({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  final String etiqueta;
  final double valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final estilo = TextStyle(
      fontSize: destacado ? 16 : 15,
      fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
      color: destacado ? AppColors.primario : AppColors.texto,
    );
    return Row(
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 15, color: AppColors.textoTenue)),
        const Spacer(),
        Text(pesos(valor), style: estilo),
      ],
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado(this.estado);

  final String estado;

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      'pendiente' => ('Pendiente', AppColors.alerta),
      'confirmada' => ('Confirmada', AppColors.primario),
      'completada' => ('Completada', AppColors.exito),
      _ => ('Cancelada', AppColors.textoTenue),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.pestana});

  final String pestana;

  @override
  Widget build(BuildContext context) {
    final (icono, titulo, detalle) = switch (pestana) {
      'completadas' => (
        CupertinoIcons.check_mark_circled,
        'Sin historial',
        'Cuando termines un parqueo, queda guardado aquí.',
      ),
      'canceladas' => (
        CupertinoIcons.xmark_circle,
        'Sin cancelaciones',
        'Las reservas que canceles aparecen en esta lista.',
      ),
      _ => (
        CupertinoIcons.calendar,
        'Sin reservas próximas',
        'Reserva una plaza desde el mapa y la verás aquí.',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primario.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 32, color: AppColors.primario),
          ),
          const SizedBox(height: 16),
          Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.textoTenue, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PedirCuenta extends StatelessWidget {
  const _PedirCuenta();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.tickets, size: 48, color: AppColors.primario),
            const SizedBox(height: 16),
            const Text(
              'Tus reservas',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para ver las próximas, el historial y pagar un saldo pendiente.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textoTenue, height: 1.35),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                borderRadius: BorderRadius.circular(12),
                onPressed: () => context.push('/login'),
                child: const Text('Iniciar sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _cuando(DateTime inicio, DateTime fin) {
  String dia(DateTime fecha) {
    final local = fecha.toLocal();
    return '${_dias[local.weekday - 1]} ${local.day} ${_meses[local.month - 1]}';
  }

  final a = inicio.toLocal();
  final b = fin.toLocal();
  final mismoDia = a.year == b.year && a.month == b.month && a.day == b.day;
  if (mismoDia) return '${dia(inicio)} · ${hora(a)} – ${hora(b)}';
  return '${dia(inicio)} ${hora(a)} – ${dia(fin)} ${hora(b)}';
}

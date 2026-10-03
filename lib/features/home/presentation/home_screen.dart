import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reservas/data/reservas_repository.dart';
import '../../reservas/domain/reserva.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(authControllerProvider).value;
    if (sesion == null || sesion.esInvitado) return const _HomeInvitado();

    final resumen = ref.watch(resumenProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(authControllerProvider.notifier).refrescarPerfil();
            ref.invalidate(resumenProvider);
            await ref.read(resumenProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Encabezado(
                saludo: 'Hola, ${sesion.usuario!.primerNombre} 👋',
                notificaciones: resumen.value?.notificacionesNoLeidas ?? 0,
                afiliado: resumen.value?.esAfiliado ?? false,
              ),
              switch (resumen) {
                AsyncData(:final value) => _Contenido(resumen: value),
                AsyncError(:final error) => Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: ErrorConReintento(
                    mensaje: ApiException.desde(error).mensaje,
                    alReintentar: () => ref.invalidate(resumenProvider),
                  ),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.saludo,
    this.notificaciones = 0,
    this.afiliado = false,
    this.subtitulo = 'Bienvenido,',
  });

  final String saludo;
  final String subtitulo;
  final int notificaciones;
  final bool afiliado;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primario,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 16,
        20,
        40,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: AppColors.azulTexto,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  saludo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (afiliado) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      '⭐ Plan Afiliado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'Notificaciones',
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/notificaciones'),
              icon: Badge(
                isLabelVisible: notificaciones > 0,
                label: Text('$notificaciones'),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.resumen});

  final ResumenUsuario resumen;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Contador(
                  valor: resumen.reservasProximas,
                  titulo: 'Reservas',
                  detalle: 'próximas',
                ),
                const SizedBox(width: 8),
                _Contador(
                  valor: resumen.vehiculos,
                  titulo: 'Vehículos',
                  detalle: 'registrados',
                ),
                const SizedBox(width: 8),
                _Contador(
                  valor: resumen.sesionActiva == null ? 0 : 1,
                  titulo: 'Sesiones',
                  detalle: 'activa',
                ),
              ],
            ),
            const _Titulo('Acciones rápidas'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.1,
              children: [
                _Accion(
                  icono: Icons.event_available_rounded,
                  texto: 'Nueva Reserva',
                  ruta: '/reservas/nueva',
                  push: true,
                ),
                const _Accion(
                  icono: Icons.folder_open_rounded,
                  texto: 'Mis Reservas',
                  ruta: '/reservas',
                ),
                const _Accion(
                  icono: Icons.directions_car_rounded,
                  texto: 'Mis Vehículos',
                  ruta: '/mis-plazas',
                ),
                const _Accion(
                  icono: Icons.history_rounded,
                  texto: 'Historial',
                  ruta: '/reservas?pestana=completadas',
                ),
              ],
            ),
            const _Titulo('Sesión activa'),
            if (resumen.sesionActiva case final reserva?)
              _TarjetaSesion(reserva: reserva)
            else
              const _SinSesion(),
          ],
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({
    required this.valor,
    required this.titulo,
    required this.detalle,
  });

  final int valor;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$valor',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primario,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              detalle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textoApagado,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    required this.icono,
    required this.texto,
    required this.ruta,
    this.push = false,
  });

  final IconData icono;
  final String texto;
  final String ruta;
  final bool push;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.borde),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => push ? context.push(ruta) : context.go(ruta),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: AppColors.primario, size: 26),
            const SizedBox(height: 4),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({required this.reserva});

  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    final entrada = reserva.sesion?.horaEntrada;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reserva.placa ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primario,
                    ),
                  ),
                  Text(
                    reserva.ubicacion,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textoTenue,
                    ),
                  ),
                  if (entrada != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Entrada: ${hora(entrada)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textoApagado,
                      ),
                    ),
                    _Transcurrido(desde: entrada),
                  ],
                ],
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => context.push('/sesion/${reserva.id}'),
              child: const Text('Ver sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cronómetro en vivo del tiempo de ocupación.
class _Transcurrido extends StatefulWidget {
  const _Transcurrido({required this.desde});

  final DateTime desde;

  @override
  State<_Transcurrido> createState() => _TranscurridoState();
}

class _TranscurridoState extends State<_Transcurrido> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '⏱ ${cronometro(DateTime.now().difference(widget.desde))}',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textoSecundario,
      ),
    );
  }
}

class _SinSesion extends StatelessWidget {
  const _SinSesion();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.local_parking_rounded,
              color: AppColors.textoApagado,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No tienes un vehículo parqueado ahora.',
                style: TextStyle(color: AppColors.textoTenue),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/mapa'),
              child: const Text('Buscar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeInvitado extends StatelessWidget {
  const _HomeInvitado();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Encabezado(
            subtitulo: 'Estás como invitado',
            saludo: 'Hola 👋',
          ),
          Transform.translate(
            offset: const Offset(0, -20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Crea tu cuenta para reservar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Asegura tu plaza antes de llegar, paga desde el celular y lleva el tiempo de tu parqueo.',
                        style: TextStyle(color: AppColors.textoTenue),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.push('/registro'),
                        child: const Text('Registrarme'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => context.go('/mapa'),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Ver parqueaderos cercanos'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

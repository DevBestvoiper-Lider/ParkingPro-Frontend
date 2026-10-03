import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/dispositivo.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/mapa_repository.dart';
import '../domain/filtros_mapa.dart';
import '../domain/sede_cercana.dart';
import 'mapa_providers.dart';
import 'widgets_mapa.dart';

class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen> {
  final _mapa = MapController();
  final _busqueda = TextEditingController();
  Timer? _espera;

  @override
  void dispose() {
    _espera?.cancel();
    _busqueda.dispose();
    _mapa.dispose();
    super.dispose();
  }

  void _alEscribir(String texto) {
    _espera?.cancel();
    _espera = Timer(
      const Duration(milliseconds: 400),
      () => ref.read(filtrosMapaProvider.notifier).buscar(texto),
    );
  }

  void _seleccionar(SedeCercana sede) {
    ref.read(sedeSeleccionadaProvider.notifier).seleccionar(sede.sedeId);
    _mapa.move(sede.punto, _mapa.camera.zoom < 15 ? 15 : _mapa.camera.zoom);
  }

  Future<void> _abrirLista(List<SedeCercana> sedes) async {
    final elegida = await showModalBottomSheet<SedeCercana>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ListaSedes(
        sedes: sedes,
        seleccionada: ref.read(sedeSeleccionadaProvider),
      ),
    );
    if (elegida != null) _seleccionar(elegida);
  }

  Future<void> _abrirFiltros() async {
    final actuales = ref.read(filtrosMapaProvider);
    final nuevos = await showModalBottomSheet<FiltrosMapa>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _Filtros(iniciales: actuales),
    );
    if (nuevos != null) {
      ref.read(filtrosMapaProvider.notifier).actualizar(nuevos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ubicacion = ref.watch(ubicacionProvider);
    final sedes = ref.watch(sedesCercanasProvider);
    final seleccionadaId = ref.watch(sedeSeleccionadaProvider);
    final lista = sedes.value ?? const <SedeCercana>[];
    final seleccionada = lista
        .where((s) => s.sedeId == seleccionadaId)
        .firstOrNull;
    final centro = ubicacion.value?.punto ?? centroCartagena;
    final arriba = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          if (!ubicacion.hasValue)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapa,
              options: MapOptions(
                initialCenter: centro,
                initialZoom: 14,
                minZoom: 5,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (_, _) => ref
                    .read(sedeSeleccionadaProvider.notifier)
                    .seleccionar(null),
              ),
              children: [
                if (ref.watch(mostrarMosaicosProvider))
                  TileLayer(
                    // Servidor público de OpenStreetMap: bien para desarrollo. En producción, usar un proveedor
                    // de mosaicos (MapTiler, Stadia, etc.) según su política de uso.
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'co.parkingpro.parkingpro',
                  ),
                MarkerLayer(
                  markers: [
                    for (final sede in lista.where(
                      (s) => s.sedeId != seleccionadaId,
                    ))
                      _marcador(sede, seleccionado: false),
                    if (seleccionada != null)
                      _marcador(seleccionada, seleccionado: true),
                    // Al final para quedar encima de los pines.
                    if (ubicacion.value?.real ?? false)
                      Marker(
                        point: ubicacion.value!.punto,
                        width: 44,
                        height: 40,
                        alignment: Alignment.center,
                        child: const MarcadorTu(),
                      ),
                  ],
                ),
                const _Atribucion(),
              ],
            ),
          // Buscador
          Positioned(
            top: arriba + 10,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Buscador(
                  controller: _busqueda,
                  alEscribir: _alEscribir,
                  alFiltrar: _abrirFiltros,
                ),
                if (sedes.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                if (ubicacion.hasValue && !ubicacion.value!.real)
                  const _Aviso(
                    'Mostrando Cartagena · activa tu ubicación para ver lo más cercano',
                  ),
                if (sedes.hasError && !sedes.isLoading)
                  _Aviso(ApiException.desde(sedes.error!).mensaje, error: true),
              ],
            ),
          ),
          // Mi ubicación
          Positioned(
            right: 12,
            bottom: seleccionada != null ? 236 : 76,
            child: FloatingActionButton.small(
              heroTag: 'mi-ubicacion',
              tooltip: 'Mi ubicación',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primario,
              onPressed: () => _mapa.move(centro, 15),
              child: const Icon(Icons.my_location),
            ),
          ),
          if (seleccionada != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _TarjetaSede(sede: seleccionada),
            )
          else if (sedes.hasValue)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.texto,
                    minimumSize: const Size(0, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: lista.isEmpty ? null : () => _abrirLista(lista),
                  icon: const Icon(Icons.list_rounded, size: 18),
                  label: Text(
                    lista.isEmpty
                        ? 'No hay parqueaderos en esta zona'
                        : 'Ver lista · ${lista.length} ${lista.length == 1 ? 'lugar' : 'lugares'}',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Marker _marcador(SedeCercana sede, {required bool seleccionado}) => Marker(
    point: sede.punto,
    width: 110,
    height: 36,
    alignment: Alignment.topCenter,
    // El pico del pin queda sobre el punto; la etiqueta se achica si no cabe.
    child: Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: PinPrecio(
          sede: sede,
          seleccionado: seleccionado,
          alTocar: () => _seleccionar(sede),
        ),
      ),
    ),
  );
}

class _Buscador extends StatelessWidget {
  const _Buscador({
    required this.controller,
    required this.alEscribir,
    required this.alFiltrar,
  });

  final TextEditingController controller;
  final ValueChanged<String> alEscribir;
  final VoidCallback alFiltrar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.textoApagado, size: 20),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: alEscribir,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Buscar parqueadero...',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
              ),
            ),
          ),
          TextButton(onPressed: alFiltrar, child: const Text('Filtros')),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto, {this.error = false});

  final String texto;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: error
              ? AppColors.error
              : AppColors.texto.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          texto,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

/// Tarjeta de la sede elegida: precio, cupos, cuántos la están viendo, reservar y cómo llegar.
class _TarjetaSede extends ConsumerStatefulWidget {
  const _TarjetaSede({required this.sede});

  final SedeCercana sede;

  @override
  ConsumerState<_TarjetaSede> createState() => _TarjetaSedeState();
}

class _TarjetaSedeState extends ConsumerState<_TarjetaSede> {
  Timer? _latido;
  int? _viendo;

  @override
  void initState() {
    super.initState();
    _marcarInteres();
    // El interés expira a los 2 min en la API: se renueva cada minuto mientras la tarjeta esté abierta.
    _latido = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _marcarInteres(),
    );
  }

  @override
  void didUpdateWidget(_TarjetaSede anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.sede.sedeId != widget.sede.sedeId) {
      _viendo = null;
      _marcarInteres();
    }
  }

  @override
  void dispose() {
    _latido?.cancel();
    super.dispose();
  }

  Future<void> _marcarInteres() async {
    try {
      final dispositivo = await ref.read(dispositivoIdProvider.future);
      final viendo = await ref
          .read(mapaRepositoryProvider)
          .marcarInteres(widget.sede.sedeId, dispositivoId: dispositivo);
      if (mounted) setState(() => _viendo = viendo);
    } catch (_) {
      // El contador es informativo: si falla, la tarjeta sigue funcionando.
    }
  }

  Future<void> _comoLlegar() async {
    final p = widget.sede.punto;
    final esIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final url = esIos
        ? Uri.parse(
            'https://maps.apple.com/?daddr=${p.latitude},${p.longitude}&dirflg=d',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}&travelmode=driving',
          );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la app de mapas')),
      );
    }
  }

  void _reservar() {
    final esInvitado =
        ref.read(authControllerProvider).value?.esInvitado ?? true;
    if (esInvitado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inicia sesión para reservar'),
          action: SnackBarAction(
            label: 'Entrar',
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }
    context.push('/reservas/nueva?sede=${widget.sede.sedeId}');
  }

  @override
  Widget build(BuildContext context) {
    final sede = widget.sede;
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sede.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${sede.parqueaderoNombre} · ${sede.distanciaTexto}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoTenue,
                        ),
                      ),
                      Text(
                        sede.direccion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textoTenue,
                        ),
                      ),
                    ],
                  ),
                ),
                PrecioHora(valor: sede.precioHoraDesde),
                IconButton(
                  tooltip: 'Cerrar',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(sedeSeleccionadaProvider.notifier)
                      .seleccionar(null),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            BarraDisponibilidad(sede: sede),
            if (_viendo != null && _viendo! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.visibility_outlined,
                    size: 16,
                    color: AppColors.textoTenue,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _viendo == 1
                          ? 'Solo tú estás viendo este lugar'
                          : '$_viendo personas están viendo este lugar',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textoTenue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: _comoLlegar,
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text('Cómo llegar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: sede.espaciosLibres == 0 ? null : _reservar,
                    child: const Text('Reservar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListaSedes extends StatelessWidget {
  const _ListaSedes({required this.sedes, required this.seleccionada});

  final List<SedeCercana> sedes;
  final String? seleccionada;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borde,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${sedes.length} parqueaderos cercanos',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              itemCount: sedes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final sede = sedes[i];
                final activa = sede.sedeId == seleccionada;
                return Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: activa ? AppColors.primario : AppColors.borde,
                      width: activa ? 2 : 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(context, sede),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sede.nombre,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${sede.direccion} · ${sede.distanciaTexto}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textoTenue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PrecioHora(
                                valor: sede.precioHoraDesde,
                                tamano: 15,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          BarraDisponibilidad(sede: sede),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Filtros extends StatefulWidget {
  const _Filtros({required this.iniciales});

  final FiltrosMapa iniciales;

  @override
  State<_Filtros> createState() => _FiltrosState();
}

class _FiltrosState extends State<_Filtros> {
  late String _tipo = widget.iniciales.tipo;
  late double _radio = widget.iniciales.radioKm;

  static const _tipos = {
    'carro': ('Carro', Icons.directions_car),
    'moto': ('Moto', Icons.two_wheeler),
    'discapacitado': ('Discapacidad', Icons.accessible),
  };
  static const _radios = [1.0, 3.0, 5.0, 10.0];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tipo de espacio',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final MapEntry(key: tipo, value: (texto, icono))
                    in _tipos.entries)
                  ChoiceChip(
                    avatar: Icon(icono, size: 18),
                    label: Text(texto),
                    selected: _tipo == tipo,
                    onSelected: (_) => setState(() => _tipo = tipo),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Distancia máxima',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final radio in _radios)
                  ChoiceChip(
                    label: Text('${radio.toStringAsFixed(0)} km'),
                    selected: _radio == radio,
                    onSelected: (_) => setState(() => _radio = radio),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                widget.iniciales.copyWith(tipo: _tipo, radioKm: _radio),
              ),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Crédito exigido por la licencia de OpenStreetMap.
class _Atribucion extends StatelessWidget {
  const _Atribucion();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        color: Colors.white70,
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 9, color: AppColors.textoTenue),
        ),
      ),
    );
  }
}

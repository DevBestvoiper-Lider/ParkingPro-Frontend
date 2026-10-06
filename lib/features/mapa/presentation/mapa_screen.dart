import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    if (ref.read(sedeSeleccionadaProvider) != sede.sedeId) {
      ref.read(rutaActivaProvider.notifier).limpiar();
    }
    ref.read(sedeSeleccionadaProvider.notifier).seleccionar(sede.sedeId);
    _mapa.move(sede.punto, _mapa.camera.zoom < 15 ? 15 : _mapa.camera.zoom);
  }

  void _cerrarSede() {
    ref.read(sedeSeleccionadaProvider.notifier).seleccionar(null);
    ref.read(rutaActivaProvider.notifier).limpiar();
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
    final ruta = ref.watch(rutaActivaProvider).asData?.value;

    ref.listen(rutaActivaProvider, (anterior, siguiente) {
      final puntos = siguiente.asData?.value?.ruta.puntos;
      final previa = anterior?.asData?.value?.ruta;
      if (puntos == null || puntos.length < 2 || previa == siguiente.asData?.value?.ruta) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          _mapa.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(puntos),
              padding: EdgeInsets.fromLTRB(36, arriba + 96, 36, 320),
            ),
          );
        } catch (_) {
          // El mapa aún no tiene tamaño (primer frame o dispose).
        }
      });
    });

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
                onTap: (_, _) => _cerrarSede(),
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
                if (ruta != null && ruta.ruta.puntos.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: ruta.ruta.puntos,
                        strokeWidth: 8,
                        color: Colors.white,
                      ),
                      Polyline(
                        points: ruta.ruta.puntos,
                        strokeWidth: 5,
                        color: AppColors.primario,
                      ),
                    ],
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
            bottom: seleccionada != null ? (ruta != null ? 420 : 236) : 76,
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

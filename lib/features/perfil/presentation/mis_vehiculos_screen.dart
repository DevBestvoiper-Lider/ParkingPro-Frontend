import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reservas/data/reservas_repository.dart';
import '../data/perfil_repository.dart';
import 'agregar_vehiculo_sheet.dart';

/// Lista, alta, edición y baja de los vehículos del usuario.
class MisVehiculosScreen extends ConsumerWidget {
  const MisVehiculosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authControllerProvider).value?.usuario;
    final texto = Theme.of(context).textTheme.bodyMedium?.fontFamily;

    return CupertinoTheme(
      data: CupertinoThemeData(
        primaryColor: AppColors.primario,
        scaffoldBackgroundColor: AppColors.fondo,
        barBackgroundColor: AppColors.fondo,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.primario,
          textStyle: TextStyle(
            fontFamily: texto,
            color: AppColors.texto,
            fontSize: 16,
          ),
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
        body: usuario == null
            ? const _PedirCuenta()
            : _Lista(usuario: usuario),
      ),
    );
  }
}

class _Lista extends ConsumerWidget {
  const _Lista({required this.usuario});

  final Usuario usuario;

  Future<void> _agregar(BuildContext context, WidgetRef ref) async {
    await formularioVehiculo(context);
  }

  Future<void> _editar(
    BuildContext context,
    WidgetRef ref,
    Vehiculo vehiculo,
  ) async {
    await formularioVehiculo(context, inicial: vehiculo);
  }

  Future<void> _eliminar(
    BuildContext context,
    WidgetRef ref,
    Vehiculo vehiculo,
  ) async {
    final confirmar = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(vehiculo.placa),
        message: const Text('El vehículo se quita de tu cuenta.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar vehículo'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Volver'),
        ),
      ),
    );
    if (confirmar != true || !context.mounted) return;
    try {
      final actualizado = await ref
          .read(perfilRepositoryProvider)
          .eliminarVehiculo(vehiculo.id);
      ref.read(authControllerProvider.notifier).actualizarUsuario(actualizado);
      ref.invalidate(resumenProvider);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.desde(e).mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiculos = usuario.vehiculos;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverNavigationBar(
          automaticallyImplyLeading: false,
          largeTitle: const Text('Mis vehículos'),
          border: null,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _agregar(context, ref),
            child: const Icon(CupertinoIcons.add),
          ),
        ),
        if (vehiculos.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _Vacio(alAgregar: () => _agregar(context, ref)),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            sliver: SliverList.separated(
              itemCount: vehiculos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final vehiculo = vehiculos[i];
                final detalle = vehiculo.descripcion;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: CupertinoListTile(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const Icon(
                      CupertinoIcons.car_fill,
                      color: AppColors.primario,
                    ),
                    title: Text(
                      vehiculo.placa,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      detalle.isEmpty ? 'Toca para agregar marca y color' : detalle,
                      style: const TextStyle(color: AppColors.textoTenue),
                    ),
                    trailing: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _eliminar(context, ref, vehiculo),
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: AppColors.error,
                        size: 22,
                      ),
                    ),
                    onTap: () => _editar(context, ref, vehiculo),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.alAgregar});

  final VoidCallback alAgregar;

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(
              CupertinoIcons.car_fill,
              size: 32,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin vehículos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Agrega la placa para poder reservar una plaza.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textoTenue,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            borderRadius: BorderRadius.circular(12),
            onPressed: alAgregar,
            child: const Text('Agregar vehículo'),
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
            const Icon(
              CupertinoIcons.car_fill,
              size: 48,
              color: AppColors.primario,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tus vehículos',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para guardar placas y usarlas al reservar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textoTenue,
                height: 1.35,
              ),
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

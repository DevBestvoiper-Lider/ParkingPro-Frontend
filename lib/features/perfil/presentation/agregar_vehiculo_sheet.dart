import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/perfil_repository.dart';

/// Abre el formulario y devuelve el vehículo creado (o null si se cancela).
Future<Vehiculo?> agregarVehiculo(BuildContext context) =>
    showModalBottomSheet<Vehiculo>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _AgregarVehiculo(),
    );

class _AgregarVehiculo extends ConsumerStatefulWidget {
  const _AgregarVehiculo();

  @override
  ConsumerState<_AgregarVehiculo> createState() => _AgregarVehiculoState();
}

class _AgregarVehiculoState extends ConsumerState<_AgregarVehiculo> {
  final _form = GlobalKey<FormState>();
  final _placa = TextEditingController();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _color = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_placa, _marca, _modelo, _color]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final placa = _placa.text.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
      final usuario = await ref
          .read(perfilRepositoryProvider)
          .agregarVehiculo(
            placa: placa,
            marca: _marca.text.trim(),
            modelo: _modelo.text.trim(),
            color: _color.text.trim(),
          );
      ref.read(authControllerProvider.notifier).actualizarUsuario(usuario);
      if (mounted) {
        Navigator.pop(
          context,
          usuario.vehiculos.firstWhere((v) => v.placa == placa),
        );
      }
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Agregar vehículo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placa,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(
                labelText: 'Placa',
                hintText: 'ABC123',
              ),
              validator: (v) {
                final limpia = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                return limpia.length < 5 ? 'Escribe la placa completa' : null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _marca,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Marca'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _modelo,
                    decoration: const InputDecoration(labelText: 'Modelo'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _color,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Color'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              MensajeError(_error!),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Guardar vehículo'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/mensaje_error.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../reservas/data/reservas_repository.dart';
import '../data/perfil_repository.dart';

/// Abre el formulario y devuelve el vehículo guardado (o null si se cancela).
Future<Vehiculo?> agregarVehiculo(BuildContext context) =>
    formularioVehiculo(context);

Future<Vehiculo?> formularioVehiculo(
  BuildContext context, {
  Vehiculo? inicial,
}) => showModalBottomSheet<Vehiculo>(
  context: context,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (_) => _AgregarVehiculo(inicial: inicial),
);

class _AgregarVehiculo extends ConsumerStatefulWidget {
  const _AgregarVehiculo({this.inicial});

  final Vehiculo? inicial;

  @override
  ConsumerState<_AgregarVehiculo> createState() => _AgregarVehiculoState();
}

class _AgregarVehiculoState extends ConsumerState<_AgregarVehiculo> {
  final _form = GlobalKey<FormState>();
  late final _placa = TextEditingController(text: widget.inicial?.placa);
  late final _marca = TextEditingController(text: widget.inicial?.marca);
  late final _modelo = TextEditingController(text: widget.inicial?.modelo);
  late final _color = TextEditingController(text: widget.inicial?.color);
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
      final marca = _marca.text.trim();
      final modelo = _modelo.text.trim();
      final color = _color.text.trim();
      final repo = ref.read(perfilRepositoryProvider);
      final inicial = widget.inicial;
      final usuario = inicial == null
          ? await repo.agregarVehiculo(
              placa: placa,
              marca: marca,
              modelo: modelo,
              color: color,
            )
          : await repo.actualizarVehiculo(
              inicial.id,
              placa: placa,
              marca: marca,
              modelo: modelo,
              color: color,
            );
      ref.read(authControllerProvider.notifier).actualizarUsuario(usuario);
      ref.invalidate(resumenProvider);
      final guardado = usuario.vehiculos
          .where((v) => inicial != null ? v.id == inicial.id : v.placa == placa)
          .firstOrNull;
      if (!mounted) return;
      if (guardado == null) {
        setState(() => _error = 'No se pudo guardar el vehículo');
        return;
      }
      Navigator.pop(context, guardado);
    } catch (e) {
      setState(() => _error = ApiException.desde(e).mensaje);
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
            Text(
              widget.inicial == null ? 'Agregar vehículo' : 'Editar vehículo',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                  : Text(
                      widget.inicial == null
                          ? 'Guardar vehículo'
                          : 'Guardar cambios',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

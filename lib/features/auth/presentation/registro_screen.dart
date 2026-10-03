import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/mensaje_error.dart';
import 'auth_controller.dart';
import 'formulario_auth.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nombre, _email, _telefono, _password, _confirmacion]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .registrar(
            nombre: _nombre.text,
            email: _email.text,
            password: _password.text,
            telefono: _telefono.text,
          );
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormularioAuth(
      titulo: 'Crear cuenta',
      subtitulo: 'Reserva y paga tu parqueadero desde el celular',
      hijos: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Escribe tu nombre'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: validarEmail,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telefono,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'Mínimo 8 caracteres'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmacion,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registrar(),
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v != _password.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          MensajeError(_error!),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _cargando ? null : _registrar,
          child: _cargando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Registrarme'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.pushReplacement('/login'),
          child: const Text('¿Ya tienes cuenta? Inicia sesión'),
        ),
      ],
    );
  }
}

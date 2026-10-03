import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/mensaje_error.dart';
import 'auth_controller.dart';
import 'formulario_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _cargando = false;
  bool _verPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text, _password.text);
      // El router redirige a Inicio al detectar la sesión.
    } on ApiException catch (e) {
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormularioAuth(
      titulo: 'Iniciar sesión',
      subtitulo: 'Bienvenido de nuevo',
      hijos: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  controller: _password,
                  obscureText: !_verPassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _entrar(),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: _verPassword ? 'Ocultar' : 'Mostrar',
                      icon: Icon(
                        _verPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Escribe tu contraseña' : null,
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
          onPressed: _cargando ? null : _entrar,
          child: _cargando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : const Text('Iniciar Sesión'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.pushReplacement('/registro'),
          child: const Text('¿No tienes cuenta? Regístrate'),
        ),
      ],
    );
  }
}

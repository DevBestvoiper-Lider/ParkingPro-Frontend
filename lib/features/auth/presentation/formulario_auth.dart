import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/logo.dart';

/// Estructura común de Login y Registro: encabezado azul y tarjeta con el formulario.
class FormularioAuth extends StatelessWidget {
  const FormularioAuth({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.hijos,
  });

  final String titulo;
  final String subtitulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.azulProfundo,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: degradadoMarca),
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 24),
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    const LogoParkingPro(tamano: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitulo,
                            style: const TextStyle(
                              color: AppColors.azulSuave,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: hijos,
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

String? validarEmail(String? valor) {
  final v = valor?.trim() ?? '';
  if (v.isEmpty) return 'Escribe tu email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Email no válido';
  }
  return null;
}

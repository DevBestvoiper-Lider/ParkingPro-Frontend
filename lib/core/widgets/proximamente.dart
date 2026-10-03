import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pantalla temporal para secciones que aún no se construyen.
class Proximamente extends StatelessWidget {
  const Proximamente({super.key, required this.titulo, required this.icono});

  final String titulo;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: AppColors.azulSuave),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Próximamente',
              style: TextStyle(color: AppColors.textoTenue),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Barra de progreso de 4 pasos del mockup.
class Progreso extends StatelessWidget {
  const Progreso({super.key, required this.paso, this.total = 4});

  final int paso;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= paso ? AppColors.primario : AppColors.borde,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Campo de solo lectura que abre un selector al tocarlo (Sede, Fecha, Hora...).
class CampoSelector extends StatelessWidget {
  const CampoSelector({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.alTocar,
    this.vacio = false,
  });

  final String etiqueta;
  final String valor;
  final IconData icono;
  final VoidCallback? alTocar;
  final bool vacio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textoTenue,
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.borde),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: alTocar,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valor,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: vacio ? AppColors.textoApagado : AppColors.texto,
                      ),
                    ),
                  ),
                  Icon(icono, size: 20, color: AppColors.primario),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fila "Etiqueta ........ Valor" del resumen y la confirmación.
class FilaDato extends StatelessWidget {
  const FilaDato(
    this.etiqueta,
    this.valor, {
    super.key,
    this.resaltar = false,
    this.ultima = false,
  });

  final String etiqueta;
  final String valor;
  final bool resaltar;
  final bool ultima;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(color: AppColors.textoTenue, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: resaltar ? FontWeight.w800 : FontWeight.w600,
                fontSize: resaltar ? 16 : 13,
                color: resaltar ? AppColors.primario : AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "2 h" o "1 h 30 min"
String textoDuracion(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return '$m min';
  return m == 0 ? '$h h' : '$h h $m min';
}

const nombresTipoEspacio = {
  'carro': 'Carro',
  'moto': 'Moto',
  'discapacitado': 'Discapacidad',
};

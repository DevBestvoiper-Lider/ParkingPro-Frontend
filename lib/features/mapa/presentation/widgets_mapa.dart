import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatos.dart';
import '../domain/sede_cercana.dart';

Color colorDisponibilidad(Disponibilidad d) => switch (d) {
  Disponibilidad.amplia => const Color(0xFF22C55E),
  Disponibilidad.pocos => const Color(0xFFF97316),
  Disponibilidad.llena => const Color(0xFFEF4444),
};

/// 4500 -> "$4.5k"
String precioCorto(double valor) => '\$${(valor / 1000).toStringAsFixed(1)}k';

/// Etiqueta de precio sobre el mapa, con un punto del color de la disponibilidad.
class PinPrecio extends StatelessWidget {
  const PinPrecio({
    super.key,
    required this.sede,
    required this.seleccionado,
    required this.alTocar,
  });

  final SedeCercana sede;
  final bool seleccionado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final fondo = seleccionado ? AppColors.texto : Colors.white;
    final precio = sede.precioHoraDesde;
    return GestureDetector(
      onTap: alTocar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: seleccionado ? 0.3 : 0.18,
                  ),
                  blurRadius: seleccionado ? 10 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: colorDisponibilidad(sede.disponibilidad),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  precio == null ? 'P' : '${precioCorto(precio)}/h',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: seleccionado ? Colors.white : AppColors.texto,
                  ),
                ),
              ],
            ),
          ),
          CustomPaint(size: const Size(10, 5), painter: _Pico(fondo)),
        ],
      ),
    );
  }
}

class _Pico extends CustomPainter {
  _Pico(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Pico old) => old.color != color;
}

/// Marcador azul "📍 Tú".
class MarcadorTu extends StatelessWidget {
  const MarcadorTu({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primario,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: AppColors.primario.withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Text(
            'Tú',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primario,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra de ocupación + "18 libres".
class BarraDisponibilidad extends StatelessWidget {
  const BarraDisponibilidad({super.key, required this.sede});

  final SedeCercana sede;

  @override
  Widget build(BuildContext context) {
    final color = colorDisponibilidad(sede.disponibilidad);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: sede.ocupacion.clamp(0, 1).toDouble(),
              minHeight: 4,
              color: color,
              backgroundColor: AppColors.borde,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          sede.espaciosLibres == 0 ? 'Lleno' : '${sede.espaciosLibres} libres',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Precio grande "$4.500/h".
class PrecioHora extends StatelessWidget {
  const PrecioHora({super.key, required this.valor, this.tamano = 17});

  final double? valor;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    if (valor == null) {
      return const Text(
        'Sin tarifa',
        style: TextStyle(color: AppColors.textoApagado),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: pesos(valor!),
            style: TextStyle(fontSize: tamano, fontWeight: FontWeight.w900),
          ),
          const TextSpan(
            text: '/h',
            style: TextStyle(fontSize: 11, color: AppColors.textoApagado),
          ),
        ],
      ),
    );
  }
}

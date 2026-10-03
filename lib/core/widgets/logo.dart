import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LogoParkingPro extends StatelessWidget {
  const LogoParkingPro({super.key, this.tamano = 80});

  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(tamano / 4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        'P',
        style: TextStyle(
          fontSize: tamano / 2,
          fontWeight: FontWeight.w900,
          color: AppColors.primario,
          height: 1,
        ),
      ),
    );
  }
}

/// Fondo azul en degradado del Splash del mockup.
const degradadoMarca = LinearGradient(
  begin: Alignment(-0.6, -1),
  end: Alignment(0.6, 1),
  colors: [
    AppColors.azulProfundo,
    AppColors.primarioOscuro,
    AppColors.azulClaro,
  ],
  stops: [0, 0.6, 1],
);

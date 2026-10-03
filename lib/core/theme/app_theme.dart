import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores del mockup de ParkingPro.
abstract final class AppColors {
  static const primario = Color(0xFF2563EB);
  static const primarioOscuro = Color(0xFF1D4ED8);
  static const azulProfundo = Color(0xFF1E3A8A);
  static const azulClaro = Color(0xFF3B82F6);
  static const azulSuave = Color(0xFF93C5FD);
  static const azulTexto = Color(0xFFBFDBFE);
  static const fondo = Color(0xFFF0F4F8);
  static const superficie = Colors.white;
  static const borde = Color(0xFFE2E8F0);
  static const texto = Color(0xFF0F172A);
  static const textoSecundario = Color(0xFF334155);
  static const textoTenue = Color(0xFF64748B);
  static const textoApagado = Color(0xFF94A3B8);
  static const exito = Color(0xFF16A34A);
  static const alerta = Color(0xFFD97706);
  static const error = Color(0xFFDC2626);
}

ThemeData construirTema({bool fuentesDeGoogle = true}) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primario,
      primary: AppColors.primario,
      surface: AppColors.superficie,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.fondo,
  );
  final texto = fuentesDeGoogle
      ? GoogleFonts.interTextTheme(base.textTheme)
      : base.textTheme;
  final radio = BorderRadius.circular(10);

  return base.copyWith(
    textTheme: texto.apply(
      bodyColor: AppColors.texto,
      displayColor: AppColors.texto,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.superficie,
      foregroundColor: AppColors.texto,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: radio,
        side: const BorderSide(color: AppColors.borde),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.superficie,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radio,
        borderSide: const BorderSide(color: AppColors.borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: const BorderSide(color: AppColors.borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radio,
        borderSide: const BorderSide(color: AppColors.primario, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.superficie,
      indicatorColor: AppColors.primario.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: estados.contains(WidgetState.selected)
              ? AppColors.primario
              : AppColors.textoApagado,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          color: estados.contains(WidgetState.selected)
              ? AppColors.primario
              : AppColors.textoApagado,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

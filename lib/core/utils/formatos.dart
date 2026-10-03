import 'package:intl/intl.dart';

final _miles = NumberFormat('#,##0', 'es_CO');

/// 4500 -> "$4.500"
String pesos(num valor) => '\$${_miles.format(valor)}';

/// Hora local: "08:15 AM"
String hora(DateTime fecha) =>
    DateFormat('hh:mm a', 'en_US').format(fecha.toLocal());

/// "25/05/2024 10:00 AM"
String fechaHora(DateTime fecha) =>
    DateFormat('dd/MM/yyyy hh:mm a', 'en_US').format(fecha.toLocal());

/// Duración como cronómetro: "02:35:45"
String cronometro(Duration duracion) {
  String dos(int n) => n.toString().padLeft(2, '0');
  final d = duracion.isNegative ? Duration.zero : duracion;
  return '${dos(d.inHours)}:${dos(d.inMinutes.remainder(60))}:${dos(d.inSeconds.remainder(60))}';
}

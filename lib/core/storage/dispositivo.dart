import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Identificador aleatorio del dispositivo, para contar a los invitados que ven una sede.
final dispositivoIdProvider = FutureProvider<String>((ref) async {
  const storage = FlutterSecureStorage();
  const clave = 'parkingpro_dispositivo';
  final guardado = await storage.read(key: clave);
  if (guardado != null) return guardado;
  final random = Random.secure();
  final nuevo = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  await storage.write(key: clave, value: nuevo);
  return nuevo;
});

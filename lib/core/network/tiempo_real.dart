import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';

/// Eventos en vivo de una sede (check-in, check-out, reservas, cambios de plaza).
/// Se conecta a `ws://<host>/api/v1/ws/sedes/{sedeId}` y se cierra al dejar de usarse.
final eventosSedeProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, sedeId) {
      final base = Env.apiUrl.replaceFirst(
        RegExp('^http'),
        'ws',
      ); // http -> ws, https -> wss
      final canal = WebSocketChannel.connect(
        Uri.parse('$base/ws/sedes/$sedeId'),
      );
      ref.onDispose(canal.sink.close);
      return canal.stream.map(
        (mensaje) => jsonDecode(mensaje as String) as Map<String, dynamic>,
      );
    });

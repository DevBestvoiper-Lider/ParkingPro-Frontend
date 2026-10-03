import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';

/// Se llama cuando la API responde 401 a una petición autenticada (token vencido).
typedef AlExpirarSesion = void Function();

Dio crearDio({
  required TokenStorage tokens,
  required AlExpirarSesion alExpirarSesion,
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? Env.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.actual;
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (error, handler) {
        final conToken = error.requestOptions.headers.containsKey(
          'Authorization',
        );
        if (error.response?.statusCode == 401 && conToken) alExpirarSesion();
        handler.next(error);
      },
    ),
  );
  return dio;
}

/// Se sobreescribe en main.dart para conectar el 401 con el cierre de sesión.
final alExpirarSesionProvider = Provider<AlExpirarSesion>((ref) => () {});

final dioProvider = Provider<Dio>((ref) {
  return crearDio(
    tokens: ref.watch(tokenStorageProvider),
    alExpirarSesion: () => ref.read(alExpirarSesionProvider)(),
  );
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/usuario.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  /// Devuelve el token. La API usa OAuth2: se envía como formulario, con el email en `username`.
  Future<String> login(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/usuarios/login',
        data: {'username': email.trim(), 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      return res.data!['access_token'] as String;
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    try {
      await _dio.post(
        '/auth/usuarios/registro',
        data: {
          'nombre': nombre.trim(),
          'email': email.trim(),
          'password': password,
          if (telefono != null && telefono.trim().isNotEmpty)
            'telefono': telefono.trim(),
        },
      );
    } catch (e) {
      throw ApiException.desde(e);
    }
  }

  Future<Usuario> perfil() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/usuarios/me');
      return Usuario.fromJson(res.data!);
    } catch (e) {
      throw ApiException.desde(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

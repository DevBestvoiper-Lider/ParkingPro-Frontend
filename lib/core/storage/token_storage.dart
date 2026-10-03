import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda el token de sesión en el llavero del dispositivo (Keychain / Keystore).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _clave = 'parkingpro_token';
  final FlutterSecureStorage _storage;
  String? _cache;

  Future<String?> leer() async => _cache ??= await _storage.read(key: _clave);

  /// Token en memoria, sin ir al llavero (para el interceptor HTTP).
  String? get actual => _cache;

  Future<void> guardar(String token) async {
    _cache = token;
    await _storage.write(key: _clave, value: token);
  }

  Future<void> borrar() async {
    _cache = null;
    await _storage.delete(key: _clave);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../data/auth_repository.dart';
import '../domain/sesion.dart';
import '../domain/usuario.dart';

/// `null` = aún no eligió (pantalla de bienvenida); `Sesion` = invitado o usuario con sesión.
class AuthController extends AsyncNotifier<Sesion?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStorage get _tokens => ref.read(tokenStorageProvider);

  @override
  Future<Sesion?> build() async {
    final token = await _tokens.leer();
    if (token == null) return null;
    try {
      return Sesion.usuario(await _repo.perfil());
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _tokens.borrar(); // token vencido
        return null;
      }
      rethrow; // sin conexión: la pantalla ofrece reintentar
    }
  }

  Future<void> login(String email, String password) async {
    final token = await _repo.login(email, password);
    await _tokens.guardar(token);
    state = AsyncData(Sesion.usuario(await _repo.perfil()));
  }

  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {
    await _repo.registrar(
      nombre: nombre,
      email: email,
      password: password,
      telefono: telefono,
    );
    await login(email, password);
  }

  /// Vuelve a leer el perfil (por ejemplo, después de agregar un vehículo).
  Future<void> refrescarPerfil() async {
    if (state.value?.esInvitado ?? true) return;
    state = AsyncData(Sesion.usuario(await _repo.perfil()));
  }

  /// Reemplaza los datos del usuario (por ejemplo, tras agregar un vehículo).
  void actualizarUsuario(Usuario usuario) =>
      state = AsyncData(Sesion.usuario(usuario));

  void continuarComoInvitado() => state = const AsyncData(Sesion.invitado());

  Future<void> cerrarSesion() async {
    await _tokens.borrar();
    state = const AsyncData(null);
  }

  /// El token venció mientras se usaba la app.
  void expirarSesion() {
    if (state.value?.esInvitado ?? true) return;
    cerrarSesion();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, Sesion?>(
  AuthController.new,
);

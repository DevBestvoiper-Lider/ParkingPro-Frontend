import 'usuario.dart';

/// Estado de acceso a la app. `usuario == null` significa invitado.
class Sesion {
  const Sesion.invitado() : usuario = null;
  const Sesion.usuario(Usuario this.usuario);

  final Usuario? usuario;

  bool get esInvitado => usuario == null;
}

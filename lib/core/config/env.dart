import 'package:flutter/foundation.dart';

/// URL de la API. Se puede cambiar al compilar:
/// `flutter run --dart-define=API_URL=http://192.168.1.10:8000/api/v1`
class Env {
  static const _apiUrl = String.fromEnvironment('API_URL');

  /// Servidor desplegado (sin HTTPS todavía: ver la excepción en Info.plist y network_security_config.xml).
  static const servidor = 'http://bestcontactcenter.bestvoiper.com:8000/api/v1';

  static String get apiUrl {
    if (_apiUrl.isNotEmpty) return _apiUrl;
    // Las versiones release (las que se instalan en celulares) usan el servidor.
    if (kReleaseMode) return servidor;
    // En desarrollo, la API local. El emulador de Android ve la Mac como 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }
}

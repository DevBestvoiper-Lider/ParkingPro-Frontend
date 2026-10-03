import 'package:dio/dio.dart';

/// Error de la API con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  ApiException(this.mensaje, {this.statusCode});

  final String mensaje;
  final int? statusCode;

  factory ApiException.desde(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final respuesta = error.response;
      if (respuesta == null) {
        return ApiException(
          'No hay conexión con el servidor. Revisa tu internet e intenta de nuevo.',
        );
      }
      return ApiException(
        _detalle(respuesta.data) ??
            'Ocurrió un error (${respuesta.statusCode}).',
        statusCode: respuesta.statusCode,
      );
    }
    return ApiException('Ocurrió un error inesperado.');
  }

  /// FastAPI responde `{"detail": "texto"}` o `{"detail": [{"loc": [...], "msg": "..."}]}`.
  static String? _detalle(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final primero = detail.first;
      if (primero is Map && primero['msg'] is String) {
        final campo =
            (primero['loc'] is List && (primero['loc'] as List).isNotEmpty)
            ? (primero['loc'] as List).last.toString()
            : null;
        final msg = (primero['msg'] as String).replaceFirst(
          'Value error, ',
          '',
        );
        return campo == null ? msg : '$campo: $msg';
      }
    }
    return null;
  }

  @override
  String toString() => mensaje;
}

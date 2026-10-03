import 'package:dio/dio.dart';
import 'package:parkingpro/core/network/api_exception.dart';
import 'package:parkingpro/core/storage/token_storage.dart';
import 'package:parkingpro/features/auth/data/auth_repository.dart';
import 'package:parkingpro/features/auth/domain/usuario.dart';
import 'package:latlong2/latlong.dart';
import 'package:parkingpro/features/mapa/data/mapa_repository.dart';
import 'package:parkingpro/features/mapa/domain/filtros_mapa.dart';
import 'package:parkingpro/features/mapa/domain/sede_cercana.dart';
import 'package:parkingpro/features/nueva_reserva/data/nueva_reserva_repository.dart';
import 'package:parkingpro/features/nueva_reserva/domain/modelos.dart';
import 'package:parkingpro/features/reservas/data/reservas_repository.dart';
import 'package:parkingpro/features/reservas/domain/reserva.dart';

class TokensEnMemoria extends TokenStorage {
  TokensEnMemoria([this._token]);

  String? _token;

  @override
  Future<String?> leer() async => _token;

  @override
  String? get actual => _token;

  @override
  Future<void> guardar(String token) async => _token = token;

  @override
  Future<void> borrar() async => _token = null;
}

const carlos = Usuario(
  id: 'u1',
  nombre: 'Carlos Pérez',
  email: 'carlos@example.com',
  vehiculos: [Vehiculo(id: 'v1', placa: 'ABC123', marca: 'Mazda')],
);

class AuthFalso extends AuthRepository {
  AuthFalso() : super(Dio());

  @override
  Future<String> login(String email, String password) async {
    if (password != 'secreto123') {
      throw ApiException('Credenciales inválidas', statusCode: 401);
    }
    return 'token-de-prueba';
  }

  @override
  Future<Usuario> perfil() async => carlos;

  @override
  Future<void> registrar({
    required String nombre,
    required String email,
    required String password,
    String? telefono,
  }) async {}
}

class ReservasFalso extends ReservasRepository {
  ReservasFalso() : super(Dio());

  @override
  Future<ResumenUsuario> resumen() async => const ResumenUsuario(
    reservasProximas: 2,
    vehiculos: 1,
    plan: 'afiliado',
    notificacionesNoLeidas: 3,
  );
}

class MapaFalso extends MapaRepository {
  MapaFalso() : super(Dio());

  final consultas = <FiltrosMapa>[];
  final intereses = <String>[];

  static const centro = SedeCercana(
    sedeId: 's1',
    parqueaderoId: 'p1',
    parqueaderoNombre: 'ParkingPro Cartagena',
    nombre: 'Sede Centro Histórico',
    direccion: 'Cl. 35 #3-20',
    ciudad: 'Cartagena',
    punto: LatLng(10.4236, -75.5510),
    distanciaKm: 0.16,
    espaciosLibres: 45,
    espaciosTotal: 47,
    interesados: 0,
    precioHoraDesde: 4500,
  );

  static const bocagrande = SedeCercana(
    sedeId: 's2',
    parqueaderoId: 'p1',
    parqueaderoNombre: 'ParkingPro Cartagena',
    nombre: 'Sede Bocagrande',
    direccion: 'Av. San Martín #6-50',
    ciudad: 'Cartagena',
    punto: LatLng(10.3997, -75.5553),
    distanciaKm: 2.6,
    espaciosLibres: 0,
    espaciosTotal: 47,
    interesados: 0,
    precioHoraDesde: 6000,
  );

  @override
  Future<List<SedeCercana>> cercanos(
    LatLng ubicacion,
    FiltrosMapa filtros,
  ) async {
    consultas.add(filtros);
    final todas = [centro, bocagrande];
    final texto = filtros.texto.toLowerCase();
    return todas
        .where((s) => texto.isEmpty || s.nombre.toLowerCase().contains(texto))
        .toList();
  }

  @override
  Future<int> marcarInteres(
    String sedeId, {
    required String dispositivoId,
    String? espacioId,
  }) async {
    intereses.add(sedeId);
    return 3;
  }
}

class NuevaReservaFalso extends NuevaReservaRepository {
  NuevaReservaFalso() : super(Dio());

  bool conflictoAlCrear = false;
  int creadas = 0;
  int pagos = 0;

  @override
  Future<List<Zona>> zonas(String sedeId) async => const [
    Zona(nombre: 'Zona A', plazas: 3),
  ];

  @override
  Future<List<Tarifa>> tarifas(String sedeId, String tipoVehiculo) async =>
      const [
        Tarifa(
          id: 't1',
          nombre: 'Tarifa carro diurna',
          tipoVehiculo: 'carro',
          valorHora: 4500,
        ),
      ];

  @override
  Future<List<Plaza>> plazas({
    required String sedeId,
    required DateTime inicio,
    required DateTime fin,
    required String tipo,
    String? zona,
  }) async => const [
    Plaza(
      id: 'e1',
      codigo: 'A-01',
      tipo: 'carro',
      estadoHorario: 'ocupada',
      zona: 'Zona A',
    ),
    Plaza(
      id: 'e2',
      codigo: 'A-02',
      tipo: 'carro',
      estadoHorario: 'disponible',
      zona: 'Zona A',
      interesados: 2,
    ),
    Plaza(
      id: 'e3',
      codigo: 'A-03',
      tipo: 'carro',
      estadoHorario: 'reservada',
      zona: 'Zona A',
    ),
  ];

  @override
  Future<int> descuentoPlan() async => 0;

  Reserva _reserva({
    required bool pagada,
    required DateTime inicio,
    required DateTime fin,
  }) => Reserva(
    id: 'r1',
    codigo: 'Rsv-000777',
    estado: pagada ? 'confirmada' : 'pendiente',
    fechaInicio: inicio,
    fechaFin: fin,
    total: 9000,
    totalPagado: pagada ? 9000 : 0,
    saldo: pagada ? 0 : 9000,
    valorHora: 4500,
    sedeId: 's1',
    espacioId: 'e2',
    sedeNombre: 'Sede Centro Histórico',
    zona: 'Zona A',
    espacioCodigo: 'A-02',
    placa: 'ABC123',
  );

  DateTime? _inicio;
  DateTime? _fin;

  @override
  Future<Reserva> crear({
    required String sedeId,
    required String espacioId,
    required String tarifaId,
    required String vehiculoId,
    required DateTime inicio,
    required DateTime fin,
  }) async {
    if (conflictoAlCrear) {
      throw ApiException(
        'El espacio ya está reservado en ese horario',
        statusCode: 409,
      );
    }
    creadas++;
    _inicio = inicio;
    _fin = fin;
    return _reserva(pagada: false, inicio: inicio, fin: fin);
  }

  @override
  Future<Reserva> pagar(String reservaId, double monto) async {
    pagos++;
    return _reserva(pagada: true, inicio: _inicio!, fin: _fin!);
  }
}

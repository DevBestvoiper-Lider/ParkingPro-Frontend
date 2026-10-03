class FiltrosMapa {
  const FiltrosMapa({this.tipo = 'carro', this.radioKm = 5, this.texto = ''});

  /// carro | moto | discapacitado
  final String tipo;
  final double radioKm;
  final String texto;

  FiltrosMapa copyWith({String? tipo, double? radioKm, String? texto}) =>
      FiltrosMapa(
        tipo: tipo ?? this.tipo,
        radioKm: radioKm ?? this.radioKm,
        texto: texto ?? this.texto,
      );

  @override
  bool operator ==(Object other) =>
      other is FiltrosMapa &&
      other.tipo == tipo &&
      other.radioKm == radioKm &&
      other.texto == texto;

  @override
  int get hashCode => Object.hash(tipo, radioKm, texto);
}

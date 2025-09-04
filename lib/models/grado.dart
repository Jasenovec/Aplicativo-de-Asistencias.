class Grado {
  final int nroGrado;
  Grado({required this.nroGrado});

  factory Grado.fromJson(Map<String, dynamic> json) {
    return Grado(nroGrado: (json['nro_grado'] ?? json['NRO_GRADO']) as int);
  }
}

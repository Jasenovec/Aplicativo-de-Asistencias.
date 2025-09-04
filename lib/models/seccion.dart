class Seccion {
  final int idSeccion;
  final String seccion;

  Seccion({required this.idSeccion, required this.seccion});

  factory Seccion.fromJson(Map<String, dynamic> json) {
    return Seccion(
      idSeccion: (json['id_seccion'] ?? json['ID_SECCION']) as int,
      seccion: (json['seccion'] ?? json['SECCION']) as String,
    );
  }
}

class Seccion {
  final int id;
  final String seccion;

  Seccion({required this.id, required this.seccion});

  factory Seccion.fromJson(Map<String, dynamic> json) {
    return Seccion(id: json['ID_SECCION'], seccion: json['SECCION']);
  }
}

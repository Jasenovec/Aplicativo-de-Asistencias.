class Estudiante {
  final int id;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String seccion;
  final int grado;

  Estudiante({
    required this.id,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.seccion,
    required this.grado,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      id: json['ID_ESTUDIANTE'],
      nombres: json['NOMBRES'],
      apellidoPaterno: json['APELLIDO_PATERNO'],
      apellidoMaterno: json['APELLIDO_MATERNO'],
      seccion: json['SECCION'],
      grado: json['NRO_GRADO'],
    );
  }
}

class Asistencia {
  final int idAsistencia;
  final String nombres;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final int grado;
  final String seccion;
  final String fecha;
  final String estadoAsistencia;
  final String? observacion;

  Asistencia({
    required this.idAsistencia,
    required this.nombres,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.grado,
    required this.seccion,
    required this.fecha,
    required this.estadoAsistencia,
    this.observacion,
  });

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      idAsistencia: json['ID_ASISTENCIA'],
      nombres: json['NOMBRES'],
      apellidoPaterno: json['APELLIDO_PATERNO'],
      apellidoMaterno: json['APELLIDO_MATERNO'],
      grado: json['NRO_GRADO'],
      seccion: json['SECCION'],
      fecha: json['FECHA'],
      estadoAsistencia: json['ESTADO_ASISTENCIA'],
      observacion: json['OBSERVACION'],
    );
  }
}

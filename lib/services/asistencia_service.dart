import '../core/api_config.dart';
import '../models/asistencia.dart';

class AsistenciaService {
  Future<void> registrarAsistencia({
    required int idEstudiante,
    required String fecha,
    required String estadoAsistencia,
    String? observacion,
  }) async {
    final body = {
      'id_estudiante': idEstudiante,
      'fecha': fecha,
      'estado_asistencia': estadoAsistencia,
      'observacion': observacion ?? '',
    };
    await ApiConfig.dio.post('/asistencia', data: body);
  }

  Future<void> actualizarAsistencia({
    required int idAsistencia,
    required String estadoAsistencia,
    String? observacion,
  }) async {
    final body = {
      'estado_asistencia': estadoAsistencia,
      'observacion': observacion ?? '',
    };
    await ApiConfig.dio.put('/asistencia/$idAsistencia', data: body);
  }

  Future<List<Asistencia>> getAsistencias() async {
    final response = await ApiConfig.dio.get('/asistencia');
    List data = response.data;
    return data.map((json) => Asistencia.fromJson(json)).toList();
  }

  Future<List<Asistencia>> getAsistenciasPorGradoSeccion(
    int grado,
    int seccion,
  ) async {
    final response = await ApiConfig.dio.get('/asistencia/$grado/$seccion');
    List data = response.data;
    return data.map((json) => Asistencia.fromJson(json)).toList();
  }

  Future<List<Asistencia>> getAsistenciasPorGradoSeccionFecha(
    int grado,
    int seccion,
    String fecha,
  ) async {
    final response = await ApiConfig.dio.get(
      '/asistencia/$grado/$seccion/$fecha',
    );
    List data = response.data;
    return data.map((json) => Asistencia.fromJson(json)).toList();
  }
}

import '../core/api_config.dart';
import '../models/estudiante.dart';

class EstudianteService {
  Future<List<Estudiante>> getEstudiantesPorGradoSeccion(
    int grado,
    int seccion,
  ) async {
    final response = await ApiConfig.dio.get('/estudiante/$grado/$seccion');
    List data = response.data;
    return data.map((json) => Estudiante.fromJson(json)).toList();
  }
}

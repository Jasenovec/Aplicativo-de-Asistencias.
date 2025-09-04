import '../core/api_config.dart';
import '../models/grado.dart';
import '../models/seccion.dart';

class ParametrosService {
  Future<List<Grado>> getGrados() async {
    final response = await ApiConfig.dio.get('/parametros/grados');
    final data = response.data as List;
    return data.map((j) => Grado.fromJson(j)).toList();
  }

  Future<List<Seccion>> getSecciones() async {
    final response = await ApiConfig.dio.get('/parametros/secciones');
    final data = response.data as List;
    return data.map((j) => Seccion.fromJson(j)).toList();
  }
}

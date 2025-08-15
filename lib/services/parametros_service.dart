import '../core/api_config.dart';
import '../models/grado.dart';
import '../models/seccion.dart';

class ParametrosService {
  Future<List<Grado>> getGrados() async {
    final response = await ApiConfig.dio.get('/parametros/grados');
    List data = response.data;
    return data.map((json) => Grado.fromJson(json)).toList();
  }

  Future<List<Seccion>> getSecciones() async {
    final response = await ApiConfig.dio.get('/parametros/secciones');
    List data = response.data;
    return data.map((json) => Seccion.fromJson(json)).toList();
  }
}

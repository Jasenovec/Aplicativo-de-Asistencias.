import 'package:flutter/material.dart';
import '../services/asistencia_service.dart';
import '../models/asistencia.dart';
import 'estudiante_viewmodel.dart';

class AsistenciaViewModel extends ChangeNotifier {
  final EstudianteViewModel? estudianteVM;
  final AsistenciaService _service = AsistenciaService();
  List<Asistencia> asistencias = [];

  bool isLoading = false;

  AsistenciaViewModel({this.estudianteVM});

  Future<void> cargarAsistencias() async {
    isLoading = true;
    notifyListeners();
    try {
      asistencias = await _service.getAsistencias();
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> actualizarAsistencia({
    required int idAsistencia,
    required String estado,
    String? observacion,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      await _service.actualizarAsistencia(
        idAsistencia: idAsistencia,
        estadoAsistencia: estado,
        observacion: observacion,
      );
      await cargarAsistencias();
    } catch (e) {
      print('Error actualizando asistencia: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> cargarAsistenciasPorGradoSeccion(
    int grado,
    int seccion, {
    required DateTime fecha,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      asistencias = await _service.getAsistenciasPorGradoSeccion(
        grado,
        seccion,
      );
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> cargarAsistenciasPorGradoSeccionFecha(
    int grado,
    int seccion,
    String fecha,
  ) async {
    isLoading = true;
    notifyListeners();
    try {
      asistencias = await _service.getAsistenciasPorGradoSeccionFecha(
        grado,
        seccion,
        fecha,
      );
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
}

import 'package:flutter/material.dart';
import 'estudiante_viewmodel.dart';
import '../services/asistencia_service.dart';

class RegistroAsistenciaViewModel extends ChangeNotifier {
  final EstudianteViewModel estudianteVM;
  final AsistenciaService _service = AsistenciaService();

  final Map<int, String> estados = {};
  final Map<int, String> observaciones = {};

  bool isLoading = false;

  RegistroAsistenciaViewModel({required this.estudianteVM});

  Future<void> registrarTodo() async {
    isLoading = true;
    notifyListeners();

    final fecha = DateTime.now().toIso8601String();
    for (var est in estudianteVM.estudiantes) {
      final estado = estados[est.id] ?? 'A';
      final obs = observaciones[est.id];
      try {
        await _service.registrarAsistencia(
          idEstudiante: est.id,
          fecha: fecha,
          estadoAsistencia: estado,
          observacion: obs,
        );
      } catch (e) {
        print('Error al registrar ${est.id}: $e');
      }
    }

    isLoading = false;
    notifyListeners();
  }

  void actualizarEstado(int idEstudiante, String estado) {
    estados[idEstudiante] = estado;
    notifyListeners();
  }
}

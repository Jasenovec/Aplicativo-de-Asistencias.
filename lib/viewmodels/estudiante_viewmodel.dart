import 'package:flutter/material.dart';
import '../models/estudiante.dart';
import '../services/estudiante_service.dart';

class EstudianteViewModel extends ChangeNotifier {
  final EstudianteService _service = EstudianteService();
  List<Estudiante> estudiantes = [];
  bool isLoading = false;

  Future<void> cargarEstudiantes(int grado, int seccion) async {
    isLoading = true;
    notifyListeners();
    try {
      estudiantes = await _service.getEstudiantesPorGradoSeccion(
        grado,
        seccion,
      );
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
}

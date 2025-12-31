import 'package:flutter/material.dart';
import '../models/seccion.dart';
import '../services/parametros_service.dart';

class SeccionViewModel extends ChangeNotifier {
  final ParametrosService _service = ParametrosService();
  List<Seccion> secciones = [];
  bool isLoading = false;

  Future<void> cargarSecciones() async {
    isLoading = true;
    notifyListeners();
    try {
      secciones = await _service.getSecciones();
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
}

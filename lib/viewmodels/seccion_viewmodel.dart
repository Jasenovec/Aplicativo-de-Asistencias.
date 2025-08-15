import 'package:flutter/material.dart';
import '../models/seccion.dart';
import '../services/parametros_service.dart';

/// ViewModel para manejar la lógica de negocio relacionada con las secciones
/// Utiliza el servicio ParametrosService para obtener datos de la API
class SeccionViewModel extends ChangeNotifier {
  final ParametrosService _service = ParametrosService();
  List<Seccion> secciones = [];
  bool isLoading = false;

  /// Carga las secciones desde el servicio y actualiza el estado
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

import 'package:flutter/material.dart';
import '../models/grado.dart';
import '../services/parametros_service.dart';

class GradosViewModel extends ChangeNotifier {
  final ParametrosService _service = ParametrosService();
  List<Grado> grados = [];
  bool isLoading = false;

  Future<void> cargarGrados() async {
    isLoading = true;
    notifyListeners();
    try {
      grados = await _service.getGrados();
    } catch (e) {
      print(e);
    }
    isLoading = false;
    notifyListeners();
  }
}

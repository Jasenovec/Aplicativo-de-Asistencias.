import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/grados_viewmodel.dart';

/// Pantalla para mostrar los grados del sistema
/// Utiliza el ViewModel GradosViewModel para obtener los datos
class GradosScreen extends StatelessWidget {
  const GradosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gradosVM = Provider.of<GradosViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Grados')),
      body:
          gradosVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: gradosVM.grados.length,
                itemBuilder: (context, index) {
                  final grado = gradosVM.grados[index];
                  return ListTile(title: Text('Grado: ${grado.nroGrado}'));
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          gradosVM.cargarGrados();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

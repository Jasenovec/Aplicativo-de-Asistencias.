import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/estudiante_viewmodel.dart';

class EstudiantesScreen extends StatelessWidget {
  final int grado;
  final int seccion;

  const EstudiantesScreen({
    super.key,
    required this.grado,
    required this.seccion,
  });

  @override
  Widget build(BuildContext context) {
    final estudianteVM = Provider.of<EstudianteViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Estudiantes')),
      body:
          estudianteVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: estudianteVM.estudiantes.length,
                itemBuilder: (context, index) {
                  final estudiante = estudianteVM.estudiantes[index];
                  return ListTile(
                    title: Text(
                      '${estudiante.apellidoPaterno} ${estudiante.apellidoMaterno}, ${estudiante.nombres}',
                    ),
                    subtitle: Text(
                      'Grado: ${estudiante.grado} - Sección: ${estudiante.seccion}',
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          estudianteVM.cargarEstudiantes(grado, seccion);
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

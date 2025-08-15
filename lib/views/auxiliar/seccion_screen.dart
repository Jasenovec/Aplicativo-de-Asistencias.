import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/seccion_viewmodel.dart';

class SeccionScreen extends StatelessWidget {
  const SeccionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seccionVM = Provider.of<SeccionViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Secciones')),
      body:
          seccionVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: seccionVM.secciones.length,
                itemBuilder: (context, index) {
                  final seccion = seccionVM.secciones[index];
                  return ListTile(title: Text('Sección: ${seccion.seccion}'));
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          seccionVM.cargarSecciones();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

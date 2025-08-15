import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Auxiliar'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.playlist_add_check),
              label: const Text('Registrar Asistencia'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
              onPressed: () {
                Navigator.pushNamed(context, '/seleccionar');
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('Ver Asistencias Registradas'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
              onPressed: () {
                Navigator.pushNamed(context, '/ver_asistencias');
              },
            ),
          ],
        ),
      ),
    );
  }
}

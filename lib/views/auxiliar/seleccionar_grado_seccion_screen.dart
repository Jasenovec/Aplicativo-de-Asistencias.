import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'asistencia_screen.dart';

class SeleccionarGradoSeccionScreen extends StatefulWidget {
  const SeleccionarGradoSeccionScreen({super.key});

  @override
  State<SeleccionarGradoSeccionScreen> createState() =>
      _SeleccionarGradoSeccionScreenState();
}

class _SeleccionarGradoSeccionScreenState
    extends State<SeleccionarGradoSeccionScreen> {
  List<int> grados = [];
  List<Map<String, dynamic>> secciones = [];

  int? gradoSeleccionado;
  int? seccionSeleccionada;

  @override
  void initState() {
    super.initState();
    cargarGrados();
    cargarSecciones();
  }

  Future<void> cargarGrados() async {
    try {
      final response = await Dio().get(
        'http://192.168.10.79:3000/parametros/grados',
      );
      setState(() {
        grados =
            List<Map<String, dynamic>>.from(
              response.data,
            ).map((e) => e['NRO_GRADO'] as int).toList();
      });
    } catch (e) {
      print('Error cargando grados: $e');
    }
  }

  Future<void> cargarSecciones() async {
    try {
      final response = await Dio().get(
        'http://192.168.10.79:3000/parametros/secciones',
      );
      setState(() {
        secciones = List<Map<String, dynamic>>.from(response.data);
      });
    } catch (e) {
      print('Error cargando secciones: $e');
    }
  }

  String nombreGrado(int nro) {
    switch (nro) {
      case 1:
        return 'Primer Año';
      case 2:
        return 'Segundo Año';
      case 3:
        return 'Tercer Año';
      case 4:
        return 'Cuarto Año';
      case 5:
        return 'Quinto Año';
      default:
        return 'Grado $nro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Grado y Sección'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<int>(
              value: gradoSeleccionado,
              hint: const Text('Seleccionar Grado'),
              isExpanded: true,
              items:
                  grados.map((g) {
                    return DropdownMenuItem<int>(
                      value: g,
                      child: Text(nombreGrado(g)),
                    );
                  }).toList(),
              onChanged: (valor) {
                setState(() {
                  gradoSeleccionado = valor;
                });
              },
            ),
            const SizedBox(height: 20),
            DropdownButton<int>(
              value: seccionSeleccionada,
              hint: const Text('Seleccionar Sección'),
              isExpanded: true,
              items:
                  secciones.map((s) {
                    return DropdownMenuItem<int>(
                      value: s['ID_SECCION'],
                      child: Text(s['SECCION']),
                    );
                  }).toList(),
              onChanged: (valor) {
                setState(() {
                  seccionSeleccionada = valor;
                });
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Continuar'),
              onPressed:
                  (gradoSeleccionado != null && seccionSeleccionada != null)
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AsistenciaScreen(
                                  grado: gradoSeleccionado!,
                                  seccion: seccionSeleccionada!,
                                ),
                          ),
                        );
                      }
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}

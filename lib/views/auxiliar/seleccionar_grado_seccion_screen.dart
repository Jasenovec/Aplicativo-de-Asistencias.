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

  bool cargandoGrados = true;
  bool cargandoSecciones = true;

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
        cargandoGrados = false;
      });
    } catch (e) {
      mostrarError('Error cargando grados');
    }
  }

  Future<void> cargarSecciones() async {
    try {
      final response = await Dio().get(
        'http://192.168.10.79:3000/parametros/secciones',
      );
      setState(() {
        secciones = List<Map<String, dynamic>>.from(response.data);
        cargandoSecciones = false;
      });
    } catch (e) {
      mostrarError('Error cargando secciones');
    }
  }

  void mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
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
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  cargandoGrados
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int>(
                        value: gradoSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Grado',
                          border: OutlineInputBorder(),
                        ),
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
                  cargandoSecciones
                      ? const CircularProgressIndicator()
                      : DropdownButtonFormField<int>(
                        value: seccionSeleccionada,
                        decoration: const InputDecoration(
                          labelText: 'Seleccionar Sección',
                          border: OutlineInputBorder(),
                        ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Continuar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          (gradoSeleccionado != null &&
                                  seccionSeleccionada != null)
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

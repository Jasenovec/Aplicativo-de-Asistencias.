import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/asistencia_viewmodel.dart';
import 'views/auxiliar/home_screen.dart';
import 'views/auxiliar/seleccionar_grado_seccion_fecha_screen.dart';
import 'views/auxiliar/seleccionar_grado_seccion_screen.dart';

void main() {
  runApp(const MyApp());
}

// Clase princal de la aplicación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AsistenciaViewModel(estudianteVM: null),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Asistencia Escolar',
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/seleccionar':
              (context) =>
                  const SeleccionarGradoSeccionScreen(), // para registrar
          '/ver_asistencias':
              (context) =>
                  const SeleccionarGradoSeccionFechaScreen(), // para ver filtradas
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/estudiante_viewmodel.dart';
import '../../viewmodels/registro_asistencia_viewmodel.dart';
import '../../models/estudiante.dart';

class AsistenciaScreen extends StatelessWidget {
  const AsistenciaScreen({
    super.key,
    required this.grado,
    required this.seccion,
  });
  final int grado;
  final int seccion;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final vm = EstudianteViewModel();
            vm.cargarEstudiantes(grado, seccion);
            return vm;
          },
        ),
        ChangeNotifierProxyProvider<
          EstudianteViewModel,
          RegistroAsistenciaViewModel
        >(
          create:
              (_) => RegistroAsistenciaViewModel(
                estudianteVM: EstudianteViewModel(),
              ),
          update:
              (_, estudianteVM, __) =>
                  RegistroAsistenciaViewModel(estudianteVM: estudianteVM),
        ),
      ],
      child: _AsistenciaInner(grado: grado, seccion: seccion),
    );
  }
}

class _AsistenciaInner extends StatelessWidget {
  const _AsistenciaInner({required this.grado, required this.seccion});
  final int grado;
  final int seccion;

  @override
  Widget build(BuildContext context) {
    final estudianteVM = Provider.of<EstudianteViewModel>(context);
    final asistenciaVM = Provider.of<RegistroAsistenciaViewModel>(context);

    if (estudianteVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Asistencia')),
      body: ListView.builder(
        itemCount: estudianteVM.estudiantes.length,
        itemBuilder: (context, i) {
          final Estudiante e = estudianteVM.estudiantes[i];
          asistenciaVM.estados.putIfAbsent(e.id, () => 'A');
          return ListTile(
            title: Text(
              '${e.apellidoPaterno} ${e.apellidoMaterno}, ${e.nombres}',
            ),
            subtitle: Column(
              children: [
                Row(
                  children:
                      ['A', 'FI', 'FJ', 'TI', 'TJ']
                          .map(
                            (s) => Row(
                              children: [
                                Radio<String>(
                                  value: s,
                                  groupValue: asistenciaVM.estados[e.id],
                                  onChanged: (v) {
                                    asistenciaVM.actualizarEstado(e.id, v!);
                                  },
                                ),
                                Text(s),
                              ],
                            ),
                          )
                          .toList(),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Observación'),
                  onChanged: (txt) => asistenciaVM.observaciones[e.id] = txt,
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton:
          asistenciaVM.isLoading
              ? const CircularProgressIndicator()
              : FloatingActionButton.extended(
                onPressed: asistenciaVM.registrarTodo,
                label: const Text('Guardar todo'),
                icon: const Icon(Icons.save),
              ),
    );
  }
}

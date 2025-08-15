import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/asistencia_viewmodel.dart';
import '../../models/asistencia.dart';

class AsistenciaListScreen extends StatefulWidget {
  final int grado;
  final int seccion;
  final String fecha;

  const AsistenciaListScreen({
    super.key,
    required this.grado,
    required this.seccion,
    required this.fecha,
  });

  @override
  State<AsistenciaListScreen> createState() => _AsistenciaListScreenState();
}

class _AsistenciaListScreenState extends State<AsistenciaListScreen> {
  late BuildContext scaffoldContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<AsistenciaViewModel>(context, listen: false);
      vm.cargarAsistenciasPorGradoSeccionFecha(
        widget.grado,
        widget.seccion,
        widget.fecha,
      );
    });
  }

  //Metodo para obtener el contexto del Scaffold
  @override
  Widget build(BuildContext context) {
    scaffoldContext = context;
    final asistenciaVM = Provider.of<AsistenciaViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Asistencias ${widget.fecha}')),
      body:
          asistenciaVM.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: asistenciaVM.asistencias.length,
                itemBuilder: (context, i) {
                  final Asistencia a = asistenciaVM.asistencias[i];
                  return ListTile(
                    title: Text(
                      '${a.apellidoPaterno} ${a.apellidoMaterno}, ${a.nombres}',
                    ),
                    subtitle: Text(
                      'Estado: ${a.estadoAsistencia} | Obs: ${a.observacion ?? "-"}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed:
                          () => _mostrarEditarDialog(context, a, asistenciaVM),
                    ),
                  );
                },
              ),
    );
  }

  // Metodo para mostrar el dialogo de edición de asistencia
  void _mostrarEditarDialog(
    BuildContext context,
    Asistencia a,
    AsistenciaViewModel vm,
  ) {
    String nuevoEstado = a.estadoAsistencia;
    String nuevaObs = a.observacion ?? '';
    final obsController = TextEditingController(text: nuevaObs);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Editar asistencia de ${a.nombres}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: nuevoEstado,
                    items:
                        ['A', 'FI', 'FJ', 'TI', 'TJ']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                    onChanged: (v) => nuevoEstado = v!,
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: obsController,
                    decoration: const InputDecoration(labelText: 'Observación'),
                    onChanged: (txt) => nuevaObs = txt,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await vm.actualizarAsistencia(
                    idAsistencia: a.idAsistencia,
                    estado: nuevoEstado,
                    observacion: nuevaObs,
                  );

                  if (!mounted) return;

                  FocusScope.of(dialogContext).unfocus();
                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Asistencia modificada exitosamente'),
                      duration: Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                      margin: EdgeInsets.all(10),
                      backgroundColor: Colors.green,
                      elevation: 5,
                      padding: EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }
}

import 'package:asistencia_app/models/grado.dart';
import 'package:asistencia_app/models/seccion.dart';
import 'package:asistencia_app/services/parametros_service.dart';
import 'package:flutter/material.dart';
import 'asistencia_screen.dart';
import 'package:intl/intl.dart';
import 'package:asistencia_app/services/asistencia_service.dart';

const _primary = Color(0xFF1E88E5);
const _primaryDark = Color(0xFF1976D2);
const _outline = Color(0xFFE5E7EB);
const _muted = Color(0xFF6B7280);

class SeleccionarGradoSeccionScreen extends StatefulWidget {
  const SeleccionarGradoSeccionScreen({super.key});

  @override
  State<SeleccionarGradoSeccionScreen> createState() =>
      _SeleccionarGradoSeccionScreenState();
}

class _SeleccionarGradoSeccionScreenState
    extends State<SeleccionarGradoSeccionScreen> {
  final _svc = ParametrosService();
  final _asistenciaSvc = AsistenciaService();

  List<Grado> grados = [];
  List<Seccion> secciones = [];

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
      final res = await _svc.getGrados();
      setState(() {
        grados = res;
        cargandoGrados = false;
      });
    } catch (e) {
      mostrarError('Error cargando grados');
      setState(() => cargandoGrados = false);
    }
  }

  Future<void> cargarSecciones() async {
    try {
      final res = await _svc.getSecciones();
      setState(() {
        secciones = res;
        cargandoSecciones = false;
      });
    } catch (e) {
      mostrarError('Error cargando secciones');
      setState(() => cargandoSecciones = false);
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
    final base = Theme.of(context);
    final localTheme = base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: _primaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: _primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: _muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _outline, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );

    return Theme(
      data: localTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar asistencia')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Card(
              color: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFF3F4F6)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Seleccione un grado y una sección',
                      style: TextStyle(
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Grado
                    cargandoGrados
                        ? const Center(
                          child: CircularProgressIndicator(color: _primary),
                        )
                        : DropdownButtonFormField<int>(
                          value: gradoSeleccionado,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar grado',
                          ),
                          items:
                              grados
                                  .map(
                                    (g) => DropdownMenuItem<int>(
                                      value: g.nroGrado,
                                      child: Text(nombreGrado(g.nroGrado)),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (valor) {
                            setState(() {
                              gradoSeleccionado = valor;
                              seccionSeleccionada = null;
                            });
                          },
                        ),

                    const SizedBox(height: 16),

                    cargandoSecciones
                        ? const Center(
                          child: CircularProgressIndicator(color: _primary),
                        )
                        : DropdownButtonFormField<int>(
                          value: seccionSeleccionada,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar sección',
                          ),
                          items:
                              secciones
                                  .map(
                                    (s) => DropdownMenuItem<int>(
                                      value: s.idSeccion,
                                      child: Text(s.seccion),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (valor) =>
                                  setState(() => seccionSeleccionada = valor),
                        ),

                    const SizedBox(height: 22),

                    Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 140),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search_rounded),
                          label: const Text('Buscar'),
                          onPressed:
                              (gradoSeleccionado != null &&
                                      seccionSeleccionada != null)
                                  ? () async {
                                    final seccionObj = secciones.firstWhere(
                                      (s) => s.idSeccion == seccionSeleccionada,
                                    );

                                    final hoy = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(DateTime.now());
                                    try {
                                      final registros = await _asistenciaSvc
                                          .getAsistenciasPorGradoSeccionFecha(
                                            gradoSeleccionado!,
                                            seccionSeleccionada!,
                                            hoy,
                                          );

                                      if (registros.isNotEmpty) {
                                        await showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder:
                                              (_) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                surfaceTintColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  side: const BorderSide(
                                                    color: _outline,
                                                  ),
                                                ),
                                                title: Row(
                                                  children: const [
                                                    Icon(
                                                      Icons
                                                          .error_outline_rounded,
                                                      color: Colors.red,
                                                      size: 50.0,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        'Asistencia ya registrada el día de hoy',
                                                        style: TextStyle(
                                                          color: _primaryDark,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                content: const Text(
                                                  'Para cambios, use “Modificar asistencia”.',
                                                  style: TextStyle(
                                                    color: _muted,
                                                    fontSize: 14.5,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          _primaryDark,
                                                      textStyle:
                                                          const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    child: const Text('Cerrar'),
                                                  ),
                                                ],
                                              ),
                                        );
                                        return;
                                      }
                                    } catch (_) {}

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => AsistenciaScreen(
                                              grado: gradoSeleccionado!,
                                              seccion: seccionSeleccionada!,
                                              seccionNombre: seccionObj.seccion,
                                            ),
                                      ),
                                    );
                                  }
                                  : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

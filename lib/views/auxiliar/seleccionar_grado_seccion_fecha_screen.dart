// lib/screens/seleccionar_grado_seccion_fecha_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:asistencia_app/models/grado.dart';
import 'package:asistencia_app/models/seccion.dart';
import 'package:asistencia_app/services/parametros_service.dart';
import 'package:asistencia_app/services/asistencia_service.dart';
import 'asistencia_list_screen.dart';
import 'asistencia_screen.dart';
import 'package:asistencia_app/utils/calendar_rules.dart';

const _primary = Color(0xFF1E88E5);
const _primaryDark = Color(0xFF1976D2);
const _outline = Color(0xFFE5E7EB);
const _muted = Color(0xFF6B7280);
const int kDiasModificables = 7;

class SeleccionarGradoSeccionFechaScreen extends StatefulWidget {
  const SeleccionarGradoSeccionFechaScreen({super.key});

  @override
  State<SeleccionarGradoSeccionFechaScreen> createState() =>
      _SeleccionarGradoSeccionFechaScreenState();
}

class _SeleccionarGradoSeccionFechaScreenState
    extends State<SeleccionarGradoSeccionFechaScreen> {
  final _svc = ParametrosService();
  final _asisSvc = AsistenciaService();

  final Set<DateTime> _diasConAsistencia = {};
  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  List<Grado> grados = [];
  List<Seccion> secciones = [];

  int? gradoSeleccionado;
  int? seccionSeleccionada;
  DateTime? fechaSeleccionada;
  DateTime focusedDay = DateTime.now();

  bool cargandoGrados = true;
  bool cargandoSecciones = true;

  DateTime get _hoySoloFecha {
    final h = DateTime.now();
    return DateTime(h.year, h.month, h.day);
  }

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

  Future<void> _cargarPuntosRango() async {
    if (gradoSeleccionado == null || seccionSeleccionada == null) {
      setState(() => _diasConAsistencia.clear());
      return;
    }

    final hoy = _hoySoloFecha;
    final minDay = hoy.subtract(const Duration(days: kDiasModificables));

    final dias = <DateTime>[];
    final futures = <Future>[];

    for (
      DateTime d = minDay;
      !d.isAfter(hoy);
      d = d.add(const Duration(days: 1))
    ) {
      dias.add(d);
      final fStr = DateFormat('yyyy-MM-dd').format(d);
      futures.add(
        _asisSvc.getAsistenciasPorGradoSeccionFecha(
          gradoSeleccionado!,
          seccionSeleccionada!,
          fStr,
        ),
      );
    }

    try {
      final results = await Future.wait(futures);
      final set = <DateTime>{};
      for (int i = 0; i < results.length; i++) {
        if ((results[i] as List).isNotEmpty) set.add(_soloFecha(dias[i]));
      }
      if (mounted)
        setState(
          () =>
              _diasConAsistencia
                ..clear()
                ..addAll(set),
        );
    } catch (_) {
      if (mounted) setState(() => _diasConAsistencia.clear());
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

  String _textoFecha() =>
      fechaSeleccionada == null
          ? 'dd / mm / aaaa'
          : DateFormat('dd / MM / yyyy').format(fechaSeleccionada!);

  Future<void> _pickDate() async {
    final today = _hoySoloFecha;
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? today,
      firstDate: DateTime(2023, 1, 1),
      lastDate: today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        fechaSeleccionada = DateTime(picked.year, picked.month, picked.day);
        focusedDay = fechaSeleccionada!;
      });
    }
  }

  Future<void> _validarYContinuar() async {
    if (gradoSeleccionado == null ||
        seccionSeleccionada == null ||
        fechaSeleccionada == null)
      return;

    final hoy = _hoySoloFecha;
    final minDay = hoy.subtract(const Duration(days: kDiasModificables));

    // No futuras
    if (fechaSeleccionada!.isAfter(hoy)) {
      mostrarError('Elija una fecha igual o anterior a hoy.');
      return;
    }

    final dSel = DateTime(
      fechaSeleccionada!.year,
      fechaSeleccionada!.month,
      fechaSeleccionada!.day,
    );

    // No laborables
    if (CalendarRules.esNoLaborable(dSel)) {
      await showNoLaborableMessage(
        context,
        detalle: 'La fecha seleccionada es no laborable.',
      );
      return;
    }

    // No más antiguas que el rango permitido
    if (dSel.isBefore(minDay)) {
      mostrarError(
        'Solo puede modificar asistencias de los últimos $kDiasModificables días.',
      );
      return;
    }

    final fechaStr = DateFormat('yyyy-MM-dd').format(fechaSeleccionada!);

    final seccionObj = secciones.firstWhere(
      (s) => s.idSeccion == seccionSeleccionada,
    );
    final letraSeccion = seccionObj.seccion;

    try {
      final registros = await AsistenciaService()
          .getAsistenciasPorGradoSeccionFecha(
            gradoSeleccionado!,
            seccionSeleccionada!,
            fechaStr,
          );

      if (registros.isEmpty) {
        if (isSameDay(fechaSeleccionada, _hoySoloFecha)) {
          // ignore: use_build_context_synchronously
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: _outline),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  title: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, color: _primaryDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Asistencias aún no registradas',
                          style: TextStyle(
                            color: _primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'No se han registrado asistencias para la fecha seleccionada.',
                    style: TextStyle(color: _muted),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: _primaryDark,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: const Text('Ir a Registrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => AsistenciaScreen(
                                  grado: gradoSeleccionado!,
                                  seccion: seccionSeleccionada!,
                                  seccionNombre: letraSeccion,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
          );
        } else {
          mostrarError('No hay asistencias registradas para esa fecha.');
        }
        return;
      }

      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => AsistenciaListScreen(
                grado: gradoSeleccionado!,
                seccion: seccionSeleccionada!,
                fecha: fechaStr,
                seccionNombre: letraSeccion,
              ),
        ),
      );
    } catch (e) {
      mostrarError('No se pudieron verificar las asistencias.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);

    final hoy = _hoySoloFecha;
    final minDay = hoy.subtract(const Duration(days: kDiasModificables));
    final lastDay = hoy;

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
        appBar: AppBar(title: const Text('Modificar asistencia')),
        body: SafeArea(
          bottom: true,
          child: ScrollConfiguration(
            behavior: const _NoGlowBehavior(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Align(
                alignment: Alignment.topCenter,
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
                          'Seleccione un grado, una sección y una fecha',
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
                                  fechaSeleccionada = null;
                                });
                                _cargarPuntosRango();
                              },
                            ),

                        const SizedBox(height: 16),

                        // Sección
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
                              onChanged: (valor) {
                                setState(() => seccionSeleccionada = valor);
                                _cargarPuntosRango();
                              },
                            ),

                        const SizedBox(height: 16),

                        // Calendario con ventana de días (sin fines de semana ni feriados)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TableCalendar(
                              locale: 'es_ES',
                              firstDay: DateTime(2023, 1, 1),
                              lastDay: lastDay,
                              eventLoader: (day) {
                                final d = _soloFecha(day);
                                return _diasConAsistencia.contains(d)
                                    ? const ['has']
                                    : const [];
                              },
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, day, events) {
                                  if (events.isEmpty)
                                    return const SizedBox.shrink();
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      width: 5,
                                      height: 5,
                                      decoration: const BoxDecoration(
                                        color: _primaryDark,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              focusedDay: () {
                                final fd = focusedDay;
                                if (fd.isAfter(lastDay)) return lastDay;
                                if (DateTime(
                                  fd.year,
                                  fd.month,
                                  fd.day,
                                ).isBefore(minDay))
                                  return minDay;
                                return fd;
                              }(),
                              // 👇 Habilita solo días hábiles dentro del rango
                              enabledDayPredicate: (day) {
                                final d = DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                );
                                final enRango =
                                    !d.isAfter(lastDay) && !d.isBefore(minDay);
                                return enRango &&
                                    !CalendarRules.esNoLaborable(d);
                              },
                              selectedDayPredicate:
                                  (day) => isSameDay(fechaSeleccionada, day),
                              onDaySelected: (selectedDay, focusDay) {
                                final d = DateTime(
                                  selectedDay.year,
                                  selectedDay.month,
                                  selectedDay.day,
                                );
                                if (CalendarRules.esNoLaborable(d)) {
                                  showNoLaborableMessage(
                                    context,
                                    detalle:
                                        'No hay clases en fines de semana ni feriados.',
                                  );
                                  return;
                                }
                                if (d.isAfter(lastDay) || d.isBefore(minDay)) {
                                  mostrarError(
                                    'Solo puede modificar asistencias de los últimos $kDiasModificables días.',
                                  );
                                  return;
                                }
                                setState(() {
                                  fechaSeleccionada = d;
                                  focusedDay = focusDay;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: _primary.withOpacity(0.18),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _primary,
                                    width: 1.2,
                                  ),
                                ),
                                selectedDecoration: const BoxDecoration(
                                  color: _primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                weekendTextStyle: const TextStyle(
                                  color: _muted,
                                ),
                                outsideTextStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                ),
                                disabledTextStyle: const TextStyle(
                                  color: Color(0xFFB0B7C3),
                                ),
                              ),
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                leftChevronIcon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: _primaryDark,
                                ),
                                rightChevronIcon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: _primaryDark,
                                ),
                                titleTextStyle: TextStyle(
                                  color: _primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Campo de fecha (solo visual)
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _textoFecha(),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'dd / mm / aaaa',
                            suffixIcon: Icon(
                              Icons.calendar_today_rounded,
                              color: _primaryDark,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Botón Buscar
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 140),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.search_rounded),
                              label: const Text('Buscar'),
                              onPressed:
                                  (gradoSeleccionado != null &&
                                          seccionSeleccionada != null &&
                                          fechaSeleccionada != null)
                                      ? _validarYContinuar
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
        ),
      ),
    );
  }
}

class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

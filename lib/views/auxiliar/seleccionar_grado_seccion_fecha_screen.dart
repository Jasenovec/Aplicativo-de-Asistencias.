import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'asistencia_list_screen.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class SeleccionarGradoSeccionFechaScreen extends StatefulWidget {
  const SeleccionarGradoSeccionFechaScreen({super.key});

  @override
  State<SeleccionarGradoSeccionFechaScreen> createState() =>
      _SeleccionarGradoSeccionFechaScreenState();
}

class _SeleccionarGradoSeccionFechaScreenState
    extends State<SeleccionarGradoSeccionFechaScreen> {
  List<int> grados = [];
  List<Map<String, dynamic>> secciones = [];

  int? gradoSeleccionado;
  int? seccionSeleccionada;
  DateTime? fechaSeleccionada;
  DateTime focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    cargarGrados();
    cargarSecciones();
  }

  Future<void> cargarGrados() async {
    final response = await Dio().get(
      'http://192.168.10.79:3000/parametros/grados',
    );
    setState(() {
      grados =
          List<Map<String, dynamic>>.from(
            response.data,
          ).map((e) => e['NRO_GRADO'] as int).toList();
    });
  }

  Future<void> cargarSecciones() async {
    final response = await Dio().get(
      'http://192.168.10.79:3000/parametros/secciones',
    );
    setState(() {
      secciones = List<Map<String, dynamic>>.from(response.data);
    });
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
      appBar: AppBar(title: const Text('Seleccionar Filtro')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<int>(
              value: gradoSeleccionado,
              hint: const Text('Seleccionar Grado'),
              isExpanded: true,
              items:
                  grados
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(nombreGrado(g)),
                        ),
                      )
                      .toList(),
              onChanged: (valor) => setState(() => gradoSeleccionado = valor),
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: seccionSeleccionada,
              hint: const Text('Seleccionar Sección'),
              isExpanded: true,
              items:
                  secciones
                      .map(
                        (s) => DropdownMenuItem(
                          value: s['ID_SECCION'] as int,
                          child: Text(s['SECCION']),
                        ),
                      )
                      .toList(),
              onChanged: (valor) => setState(() => seccionSeleccionada = valor),
            ),
            const SizedBox(height: 16),
            // Calendario integrado en un Card
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
                  lastDay: DateTime(2030, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate:
                      (day) => isSameDay(fechaSeleccionada, day),
                  onDaySelected: (selectedDay, focusDay) {
                    setState(() {
                      fechaSeleccionada = selectedDay;
                      focusedDay = focusDay;
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.indigo,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Ver Asistencias'),
              onPressed:
                  (gradoSeleccionado != null &&
                          seccionSeleccionada != null &&
                          fechaSeleccionada != null)
                      ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AsistenciaListScreen(
                                  grado: gradoSeleccionado!,
                                  seccion: seccionSeleccionada!,
                                  fecha: DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(fechaSeleccionada!),
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

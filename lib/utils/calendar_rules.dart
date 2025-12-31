import 'package:flutter/material.dart';

/// Reglas de días no laborables (fines de semana + feriados).
class CalendarRules {
  // Feriados 2025
  static const List<String> _feriadosStr = <String>[
    '2025-04-17', // Jueves Santo
    '2025-04-18', // Viernes Santo
    '2025-05-01', // Día del Trabajo
    '2025-07-28', // Fiestas Patrias
    '2025-08-30', // Santa Rosa de Lima
    '2025-10-08', // Combate de Angamos
    '2025-11-01', // Dia de todos los Santos
    '2025-12-08', // Inmaculada Concepción
    '2025-12-25', // Navidad
  ];

  static Set<DateTime> get feriados => _feriadosStr.map(_parseYmd).toSet();

  static DateTime _parseYmd(String s) {
    final p = s.split('-');
    final y = int.parse(p[0]), m = int.parse(p[1]), d = int.parse(p[2]);
    return DateTime(y, m, d);
  }

  static bool esFinDeSemana(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  static bool esFeriado(DateTime d) {
    final f = DateTime(d.year, d.month, d.day);
    return feriados.contains(f);
  }

  static bool esNoLaborable(DateTime d) => esFinDeSemana(d) || esFeriado(d);
}

Future<void> showNoLaborableMessage(
  BuildContext context, {
  String? detalle,
}) async {
  final msg = detalle ?? 'Hoy no hay clases (día no laborable).';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

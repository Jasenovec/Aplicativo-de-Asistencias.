import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/asistencia_viewmodel.dart';
import '../../models/asistencia.dart';

const _primary = Color(0xFF1E88E5); // Azul 600
const _primaryDark = Color(0xFF1976D2); // Azul 700
const _outline = Color(0xFFE5E7EB); // Gris 200
const _muted = Color(0xFF6B7280); // Gris 500

class AsistenciaListScreen extends StatefulWidget {
  final int grado;
  final int seccion;
  final String fecha; // yyyy-MM-dd
  final String? seccionNombre; // opcional, para mostrar en la cabecera

  const AsistenciaListScreen({
    super.key,
    required this.grado,
    required this.seccion,
    required this.fecha,
    this.seccionNombre,
  });

  @override
  State<AsistenciaListScreen> createState() => _AsistenciaListScreenState();
}

class _AsistenciaListScreenState extends State<AsistenciaListScreen> {
  // --- UI state (misma UX que registrar) ---
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _query = '';
  final Map<int, GlobalKey> _itemKeys = {}; // idAsistencia -> key
  Map<String, int> _letterIndex = {}; // letra -> índice en lista filtrada

  // índice alfabético fijo
  bool _isDraggingAlpha = false;
  String _currentLetter = 'A';
  double? _alphaIndicatorDy;
  final List<String> _letters = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );
  static const double _alphaRailW = 24.0;
  static const double _alphaRailPad = 8.0;

  // Causas / motivos (igual que registrar)
  static const _causasTJ = [
    'Cita médica',
    'Transporte/accidente',
    'Trámite oficial',
    'Emergencia familiar',
    'Representa a la institución',
  ];
  static const _causasFJ = [
    'Enfermedad (cert.)',
    'Luto familiar',
    'Procedimiento médico',
    'Citación oficial',
    'Contingencia mayor',
  ];
  static const _motivosInjust = ['Sin justificación'];

  // Estado local de edición (por registro)
  final Map<int, String> _estadoEditado = {}; // idAsistencia -> estado
  final Map<int, String> _observacionEditada = {}; // idAsistencia -> obs
  final Map<int, String> _causaPorRegistro =
      {}; // idAsistencia -> texto/'__otra__'

  bool _prefilled = false; // para precargar maps con valores actuales
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Cargar asistencias del día seleccionado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<AsistenciaViewModel>(context, listen: false);
      vm.cargarAsistenciasPorGradoSeccionFecha(
        widget.grado,
        widget.seccion,
        widget.fecha,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------
  List<Asistencia> _filter(List<Asistencia> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((a) {
      final nombre =
          '${a.apellidoPaterno} ${a.apellidoMaterno} ${a.nombres}'
              .toLowerCase();
      return nombre.contains(q);
    }).toList();
  }

  void _buildLetterIndex(List<Asistencia> items) {
    _letterIndex = {};
    for (int i = 0; i < items.length; i++) {
      final ap =
          (items[i].apellidoPaterno.isNotEmpty)
              ? items[i].apellidoPaterno[0].toUpperCase()
              : '#';
      _letterIndex.putIfAbsent(ap, () => i);
    }
  }

  Future<void> _jumpToLetter(String letter, List<Asistencia> items) async {
    final idx = _letterIndex[letter];
    if (idx == null) return;
    final key = _itemKeys[items[idx].idAsistencia];
    final ctx = key?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0,
      );
    }
  }

  void _onAlphaDrag(
    Offset localPos,
    double railHeight,
    List<Asistencia> items,
  ) {
    final cellH = railHeight / _letters.length;
    int idx = (localPos.dy ~/ cellH);
    idx = idx.clamp(0, _letters.length - 1);
    final letter = _letters[idx];

    setState(() {
      _isDraggingAlpha = true;
      _currentLetter = letter;
      _alphaIndicatorDy = localPos.dy.clamp(0, railHeight);
    });

    _jumpToLetter(letter, items);
  }

  void _prefillIfNeeded(List<Asistencia> list) {
    if (_prefilled) return;
    for (final a in list) {
      _estadoEditado[a.idAsistencia] = a.estadoAsistencia;
      if (a.observacion != null && a.observacion!.trim().isNotEmpty) {
        _observacionEditada[a.idAsistencia] = a.observacion!.trim();
      }
      // No inferimos causa; queda vacía hasta que el usuario toque
    }
    _prefilled = true;
  }

  String _niceFecha(String isoYmd) {
    DateTime d = DateTime.parse(isoYmd);
    return DateFormat('EEE, d MMM yyyy', 'es_PE').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AsistenciaViewModel>(context);

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
        hintStyle: const TextStyle(color: _muted),
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
    );

    final reservedBottom =
        16 + 48 + 16 + MediaQuery.of(context).padding.bottom; // paddings + btn

    if (vm.isLoading) {
      return Theme(
        data: localTheme,
        child: Scaffold(
          appBar: AppBar(title: const Text('Modificar asistencia')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final list = vm.asistencias;
    _prefillIfNeeded(list);

    final filtrados = _filter(list);
    _buildLetterIndex(filtrados);

    return Theme(
      data: localTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Modificar asistencia')),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              icon:
                  _isSaving
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  _isSaving
                      ? null
                      : () async {
                        // Guardamos solo los que cambiaron
                        setState(() => _isSaving = true);
                        try {
                          for (final a in list) {
                            final nuevoEstado =
                                _estadoEditado[a.idAsistencia] ??
                                a.estadoAsistencia;
                            final nuevaObs =
                                _observacionEditada[a.idAsistencia] ??
                                a.observacion ??
                                '';

                            final cambioEstado =
                                nuevoEstado != a.estadoAsistencia;
                            final cambioObs =
                                (nuevaObs).trim() !=
                                (a.observacion ?? '').trim();

                            if (cambioEstado || cambioObs) {
                              await vm.actualizarAsistencia(
                                idAsistencia: a.idAsistencia,
                                estado: nuevoEstado,
                                observacion: nuevaObs.trim(),
                              );
                            }
                          }

                          if (!mounted) return;
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
                                  title: Row(
                                    children: const [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 50,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Cambios guardados',
                                          style: TextStyle(
                                            color: _primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    'Las asistencias se actualizaron correctamente.',
                                    style: TextStyle(color: _muted),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        foregroundColor: _primaryDark,
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('Aceptar'),
                                    ),
                                  ],
                                ),
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop(); // ✅ salir tras guardar
                          return;
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo guardar')),
                          );
                        } finally {
                          if (mounted) setState(() => _isSaving = false);
                        }
                      },
            ),
          ),
        ),
        body: Column(
          children: [
            // Cabecera (grado/sección/fecha + buscador)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.class_outlined, size: 22, color: _primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        'Grado: ${widget.grado}º • Sección: ${widget.seccionNombre ?? widget.seccion}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 22, color: _primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        _niceFecha(widget.fecha),
                        style: const TextStyle(color: _muted, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar estudiante',
                      prefixIcon: Icon(Icons.search_rounded, color: _muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Lista + riel alfabético fijo
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16 + _alphaRailW + _alphaRailPad,
                      reservedBottom,
                    ),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final a = filtrados[i];
                      final id = a.idAsistencia;

                      _itemKeys.putIfAbsent(id, () => GlobalKey());

                      final estado = _estadoEditado[id] ?? a.estadoAsistencia;
                      final obsActual =
                          _observacionEditada[id] ?? a.observacion ?? '';

                      return Container(
                        key: _itemKeys[id],
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: _outline),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a.apellidoPaterno} ${a.apellidoMaterno}, ${a.nombres}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // ===== Estados (chips) =====
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      ['A', 'FI', 'FJ', 'TI', 'TJ'].map((s) {
                                        final selected = estado == s;
                                        return ChoiceChip(
                                          label: Text(s),
                                          selected: selected,
                                          onSelected: (_) {
                                            setState(() {
                                              _estadoEditado[id] = s;
                                              if (s == 'A') {
                                                // limpiar causa y observación
                                                _causaPorRegistro.remove(id);
                                                _observacionEditada.remove(id);
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();
                                              }
                                            });
                                          },
                                          selectedColor: _primary.withOpacity(
                                            0.15,
                                          ),
                                          labelStyle: TextStyle(
                                            color:
                                                selected
                                                    ? _primaryDark
                                                    : Colors.black87,
                                            fontWeight:
                                                selected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                          ),
                                          side: const BorderSide(
                                            color: _outline,
                                          ),
                                        );
                                      }).toList(),
                                ),

                                const SizedBox(height: 8),

                                // ===== Causas/Motivos según estado =====
                                Builder(
                                  builder: (_) {
                                    List<String>? opciones;
                                    if (estado == 'TJ') opciones = _causasTJ;
                                    if (estado == 'FJ') opciones = _causasFJ;
                                    if (estado == 'TI' || estado == 'FI')
                                      opciones = _motivosInjust;

                                    if (opciones == null) {
                                      return const SizedBox.shrink();
                                    }

                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ...opciones.map((op) {
                                          final sel =
                                              _causaPorRegistro[id] == op;
                                          return ChoiceChip(
                                            label: Text(op),
                                            selected: sel,
                                            onSelected: (_) {
                                              setState(() {
                                                _causaPorRegistro[id] = op;
                                                // si es una causa “definida”, la volcamos a obs
                                                _observacionEditada[id] = op;
                                              });
                                            },
                                            selectedColor: _primary.withOpacity(
                                              0.10,
                                            ),
                                            labelStyle: TextStyle(
                                              color:
                                                  sel
                                                      ? _primaryDark
                                                      : Colors.black87,
                                              fontWeight:
                                                  sel
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                            ),
                                            side: const BorderSide(
                                              color: _outline,
                                            ),
                                          );
                                        }),
                                        ChoiceChip(
                                          label: const Text('Otra…'),
                                          selected:
                                              _causaPorRegistro[id] ==
                                              '__otra__',
                                          onSelected: (_) {
                                            setState(() {
                                              _causaPorRegistro[id] =
                                                  '__otra__';
                                              // no sobreescribimos obs; el usuario escribe
                                            });
                                          },
                                          selectedColor: _primary.withOpacity(
                                            0.10,
                                          ),
                                          side: const BorderSide(
                                            color: _outline,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 10),

                                // ===== Observación (reglas de visibilidad) =====
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: () {
                                    final causa = _causaPorRegistro[id];
                                    final showObs =
                                        estado != 'A' &&
                                        ((estado == 'TJ' || estado == 'FJ')
                                            ? causa == '__otra__'
                                            : true);
                                    if (!showObs) {
                                      return const SizedBox.shrink(
                                        key: ValueKey('hidden'),
                                      );
                                    }
                                    return TextField(
                                      key: const ValueKey('obs'),
                                      controller: TextEditingController(
                                        text: obsActual,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Observación',
                                      ),
                                      onChanged:
                                          (txt) =>
                                              _observacionEditada[id] = txt,
                                    );
                                  }(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ===== Riel alfabético fijo =====
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: reservedBottom - 10,
                    child: SizedBox(
                      width: _alphaRailW + _alphaRailPad,
                      child: LayoutBuilder(
                        builder: (ctx, cons) {
                          final railH = cons.maxHeight;
                          final cellH = railH / _letters.length;
                          final fontSize = (cellH * 0.75).clamp(10.0, 14.0);

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown:
                                (d) => _onAlphaDrag(
                                  d.localPosition,
                                  railH,
                                  filtrados,
                                ),
                            onPanUpdate:
                                (d) => _onAlphaDrag(
                                  d.localPosition,
                                  railH,
                                  filtrados,
                                ),
                            onPanEnd:
                                (_) => setState(() => _isDraggingAlpha = false),
                            onPanCancel:
                                () => setState(() => _isDraggingAlpha = false),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    width: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    color: _outline,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children:
                                        _letters.map((letter) {
                                          final active = _letterIndex
                                              .containsKey(letter);
                                          return SizedBox(
                                            height: cellH,
                                            child: Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                letter,
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  color:
                                                      active
                                                          ? _primaryDark
                                                          : _muted.withOpacity(
                                                            0.35,
                                                          ),
                                                  fontWeight:
                                                      active
                                                          ? FontWeight.w700
                                                          : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ),
                                if (_isDraggingAlpha)
                                  Positioned(
                                    right: _alphaRailW + 8,
                                    top: ((_alphaIndicatorDy ?? railH / 2) - 22)
                                        .clamp(0.0, railH - 44),
                                    child: const _AlphaBubble(),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlphaBubble extends StatelessWidget {
  const _AlphaBubble();

  @override
  Widget build(BuildContext context) {
    // Solo muestra la “pestañita”, la letra actual ya se refleja en la lista
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _outline),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: const Icon(
          Icons.radio_button_checked,
          color: _primaryDark,
          size: 18,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/asistencia_viewmodel.dart';
import '../../models/asistencia.dart';

const _primary = Color(0xFF1E88E5);
const _primaryDark = Color(0xFF1976D2);
const _outline = Color(0xFFE5E7EB);
const _muted = Color(0xFF6B7280);

class AsistenciaListScreen extends StatefulWidget {
  final int grado;
  final int seccion;
  final String fecha;
  final String? seccionNombre;

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
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _query = '';
  final Map<int, GlobalKey> _itemKeys = {};
  Map<String, int> _letterIndex = {};

  bool _isDraggingAlpha = false;
  String _currentLetter = 'A';
  String _lastJumpedLetter = '';
  final List<String> _letters = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );

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

  final Map<int, String> _estadoEditado = {};
  final Map<int, String> _observacionEditada = {};
  final Map<int, String> _causaPorRegistro = {};

  bool _prefilled = false;
  bool _isSaving = false;

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

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
        duration: const Duration(milliseconds: 80),
        curve: Curves.linear,
      );
    }
  }

  void _handleAlphaDrag({
    required Offset localPos,
    required double railHeight,
    required List<Asistencia> items,
  }) {
    final cellH = railHeight / _letters.length;
    int idx = (localPos.dy ~/ cellH).clamp(0, _letters.length - 1);
    final letter = _letters[idx];

    if (letter != _lastJumpedLetter) {
      _lastJumpedLetter = letter;
      _jumpToLetter(letter, items);
    }

    setState(() {
      _isDraggingAlpha = true;
      _currentLetter = letter;
    });
  }

  void _prefillIfNeeded(List<Asistencia> list) {
    if (_prefilled) return;

    for (final a in list) {
      final id = a.idAsistencia;
      final estado = a.estadoAsistencia;
      final obs = (a.observacion ?? '').trim();

      _estadoEditado[id] = estado;

      if (obs.isNotEmpty) {
        _observacionEditada[id] = obs;

        List<String>? posibles;
        if (estado == 'TJ') {
          posibles = _causasTJ;
        } else if (estado == 'FJ')
          // ignore: curly_braces_in_flow_control_structures
          posibles = _causasFJ;
        else if (estado == 'TI' || estado == 'FI')
          // ignore: curly_braces_in_flow_control_structures
          posibles = _motivosInjust;

        if (posibles != null) {
          final match = posibles.firstWhere(
            (c) => obs.startsWith(c),
            orElse: () => '',
          );
          if (match.isNotEmpty) {
            _causaPorRegistro[id] = match;
          } else {
            _causaPorRegistro[id] = '__otra__';
          }
        }
      }
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

    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (vm.isLoading) {
      return Theme(
        data: localTheme,
        child: Scaffold(
          appBar: AppBar(title: const Text('Modificar asistencia')),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final double alphaRailW = (MediaQuery.of(context).size.width * 0.06).clamp(
      30.0,
      36.0,
    );

    final list = vm.asistencias;
    _prefillIfNeeded(list);

    final filtrados = _filter(list);
    _buildLetterIndex(filtrados);

    return Theme(
      data: localTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Modificar asistencia')),

        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 8),
          child: SizedBox(
            height: 56,
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
                        setState(() => _isSaving = true);
                        try {
                          for (final a in list) {
                            final nuevoEstado =
                                _estadoEditado[a.idAsistencia] ??
                                a.estadoAsistencia;
                            final nuevaObs =
                                _observacionEditada[a.idAsistencia]?.trim() ??
                                '';

                            final cambioEstado =
                                nuevoEstado != a.estadoAsistencia;
                            final cambioObs =
                                nuevaObs != (a.observacion ?? '').trim();

                            if (cambioEstado || cambioObs) {
                              await vm.actualizarAsistencia(
                                idAsistencia: a.idAsistencia,
                                estado: nuevoEstado,
                                observacion: nuevaObs,
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
                          Navigator.of(context).pop();
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

            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(16, 8, 52, 24 + bottomInset),
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
                                const SizedBox(height: 10),

                                SizedBox(
                                  height: 36,
                                  width: 320,
                                  child: ScrollConfiguration(
                                    behavior: const _NoGlowBehavior(),
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      children:
                                          ['A', 'FI', 'FJ', 'TI', 'TJ'].map((
                                            s,
                                          ) {
                                            final selected = estado == s;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: ChoiceChip(
                                                label: Text(s),
                                                selected: selected,
                                                onSelected: (_) {
                                                  setState(() {
                                                    _estadoEditado[id] = s;
                                                    if (s == 'A') {
                                                      _causaPorRegistro.remove(
                                                        id,
                                                      );
                                                      _observacionEditada
                                                          .remove(id);
                                                      FocusScope.of(
                                                        context,
                                                      ).unfocus();
                                                    }
                                                  });
                                                },
                                                selectedColor: _primary
                                                    .withOpacity(0.15),
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
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Builder(
                                  builder: (_) {
                                    List<String>? opciones;
                                    if (estado == 'TJ') opciones = _causasTJ;
                                    if (estado == 'FJ') opciones = _causasFJ;
                                    if (estado == 'TI' || estado == 'FI')
                                      opciones = _motivosInjust;

                                    if (opciones == null)
                                      return const SizedBox.shrink();

                                    // Detectar causa si aún no fue registrada
                                    if (!_causaPorRegistro.containsKey(id) &&
                                        obsActual.isNotEmpty) {
                                      final match = opciones.firstWhere(
                                        (c) => obsActual.startsWith(c),
                                        orElse: () => '',
                                      );
                                      _causaPorRegistro[id] =
                                          match.isNotEmpty ? match : '__otra__';
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
                                              if (_observacionEditada[id] ==
                                                      null ||
                                                  opciones!.any(
                                                    (c) =>
                                                        _observacionEditada[id] ==
                                                        c,
                                                  )) {
                                                _observacionEditada[id] = '';
                                              }
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

                                    final controller = TextEditingController(
                                      text: obsActual,
                                    );
                                    controller
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: controller.text.length,
                                      ),
                                    );

                                    return TextField(
                                      key: const ValueKey('obs'),
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Observación',
                                      ),
                                      onChanged: (txt) {
                                        _observacionEditada[id] = txt;

                                        if (estado == 'TJ' || estado == 'FJ') {
                                          final posibles =
                                              estado == 'TJ'
                                                  ? _causasTJ
                                                  : _causasFJ;
                                          final match = posibles.firstWhere(
                                            (c) => txt.startsWith(c),
                                            orElse: () => '',
                                          );
                                          if (match.isNotEmpty) {
                                            _causaPorRegistro[id] = match;
                                          } else {
                                            _causaPorRegistro[id] = '__otra__';
                                          }
                                        } else if (estado == 'TI' ||
                                            estado == 'FI') {
                                          _causaPorRegistro[id] = '__otra__';
                                        }
                                      },
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

                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: alphaRailW,
                      child: LayoutBuilder(
                        builder: (ctx, cons) {
                          final railH = cons.maxHeight;
                          final cellH = railH / _letters.length;
                          final fontSize = (cellH * 0.75).clamp(11.0, 16.0);

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanDown:
                                (d) => _handleAlphaDrag(
                                  localPos: d.localPosition,
                                  railHeight: railH,
                                  items: filtrados,
                                ),
                            onPanUpdate:
                                (d) => _handleAlphaDrag(
                                  localPos: d.localPosition,
                                  railHeight: railH,
                                  items: filtrados,
                                ),
                            onPanEnd:
                                (_) => setState(() {
                                  _isDraggingAlpha = false;
                                  _lastJumpedLetter = '';
                                }),
                            onPanCancel:
                                () => setState(() {
                                  _isDraggingAlpha = false;
                                  _lastJumpedLetter = '';
                                }),
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
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children:
                                      _letters.map((letter) {
                                        final active = _letterIndex.containsKey(
                                          letter,
                                        );
                                        return SizedBox(
                                          height: cellH,
                                          child: Center(
                                            child: Text(
                                              letter,
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                color: (active
                                                        ? _primaryDark
                                                        : _muted.withOpacity(
                                                          0.35,
                                                        ))
                                                    .withOpacity(0.55),
                                                fontWeight:
                                                    active
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  IgnorePointer(
                    ignoring: true,
                    child: AnimatedOpacity(
                      opacity: _isDraggingAlpha ? 1 : 0,
                      duration: const Duration(milliseconds: 100),
                      child: Center(
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _outline.withOpacity(0.9),
                            ),
                            boxShadow: const [
                              BoxShadow(blurRadius: 12, color: Colors.black12),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _currentLetter,
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w800,
                              color: _primaryDark.withOpacity(0.75),
                            ),
                          ),
                        ),
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

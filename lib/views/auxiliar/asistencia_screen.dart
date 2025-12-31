import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/estudiante_viewmodel.dart';
import '../../viewmodels/registro_asistencia_viewmodel.dart';
import '../../models/estudiante.dart';

const _primary = Color(0xFF1E88E5);
const _primaryDark = Color(0xFF1976D2);
const _outline = Color(0xFFE5E7EB);
const _muted = Color(0xFF6B7280);

class AsistenciaScreen extends StatelessWidget {
  const AsistenciaScreen({
    super.key,
    required this.grado,
    required this.seccion,
    this.seccionNombre,
  });
  final int grado;
  final int seccion;
  final String? seccionNombre;

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
      child: _AsistenciaInner(
        grado: grado,
        seccion: seccion,
        seccionNombre: seccionNombre,
      ),
    );
  }
}

class _AsistenciaInner extends StatefulWidget {
  const _AsistenciaInner({
    required this.grado,
    required this.seccion,
    this.seccionNombre,
  });
  final int grado;
  final int seccion;
  final String? seccionNombre;

  @override
  State<_AsistenciaInner> createState() => _AsistenciaInnerState();
}

class _AsistenciaInnerState extends State<_AsistenciaInner> {
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
    'Trámite oficial',
    'Emergencia familiar',
    'Transporte/accidente',
    'Representa a la institución',
  ];
  static const _causasFJ = [
    'Enfermedad',
    'Luto familiar',
    'Citación oficial',
    'Contingencia mayor',
    'Procedimiento médico',
  ];
  static const _motivosInjust = ['Sin justificación'];

  final Map<int, String> _causaPorAlumno = {};

  bool _validarCausas(RegistroAsistenciaViewModel vm) {
    for (final entry in vm.estados.entries) {
      final id = entry.key;
      final est = entry.value;
      if ((est == 'TJ' || est == 'FJ') && (_causaPorAlumno[id] == null))
        return false;
    }
    return true;
  }

  void _handleAlphaDrag({
    required Offset localPos,
    required double railHeight,
    required List<Estudiante> items,
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<Estudiante> _filter(List<Estudiante> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((e) {
      final nombre =
          '${e.apellidoPaterno} ${e.apellidoMaterno} ${e.nombres}'
              .toLowerCase();
      return nombre.contains(q);
    }).toList();
  }

  void _buildLetterIndex(List<Estudiante> items) {
    _letterIndex = {};
    for (int i = 0; i < items.length; i++) {
      final ap =
          (items[i].apellidoPaterno.isNotEmpty)
              ? items[i].apellidoPaterno[0].toUpperCase()
              : '#';
      _letterIndex.putIfAbsent(ap, () => i);
    }
  }

  Future<void> _jumpToLetter(String letter, List<Estudiante> items) async {
    final idx = _letterIndex[letter];
    if (idx == null) return;
    final key = _itemKeys[items[idx].id];
    final ctx = key?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 80),
        curve: Curves.linear,
        alignment: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estudianteVM = Provider.of<EstudianteViewModel>(context);
    final asistenciaVM = Provider.of<RegistroAsistenciaViewModel>(context);
    if (estudianteVM.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final estudiantes = _filter(estudianteVM.estudiantes);
    _buildLetterIndex(estudiantes);

    final today = DateFormat('EEE, d MMM yyyy', 'es_PE').format(DateTime.now());
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

    final double alphaRailW = (MediaQuery.of(context).size.width * 0.06).clamp(
      30.0,
      36.0,
    );

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Theme(
      data: localTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar asistencia')),

        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 8),
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              icon:
                  asistenciaVM.isLoading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save_rounded),
              label: Text(
                asistenciaVM.isLoading ? 'Guardando...' : 'Guardar todo',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  asistenciaVM.isLoading
                      ? null
                      : () async {
                        if (!_validarCausas(asistenciaVM)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecciona una causa para cada TJ/FJ',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          await asistenciaVM.registrarTodo();
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
                                        size: 48,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Guardado exitoso',
                                          style: TextStyle(
                                            color: _primaryDark,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    'La asistencia de hoy se registró correctamente.',
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
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ocurrió un error al guardar'),
                            ),
                          );
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
                        today,
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
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16 + alphaRailW + 10,
                      24,
                    ),
                    itemCount: estudiantes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final Estudiante e = estudiantes[i];
                      _itemKeys.putIfAbsent(e.id, () => GlobalKey());
                      asistenciaVM.estados.putIfAbsent(e.id, () => 'A');
                      final estado = asistenciaVM.estados[e.id];

                      return Container(
                        key: _itemKeys[e.id],
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
                                  '${e.apellidoPaterno} ${e.apellidoMaterno}, ${e.nombres}',
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
                                          [
                                              _EstadoChip(
                                                texto: 'A',
                                                selected: estado == 'A',
                                                onTap: () {
                                                  asistenciaVM.actualizarEstado(
                                                    e.id,
                                                    'A',
                                                  );
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                  asistenciaVM.observaciones
                                                      .remove(e.id);
                                                  _causaPorAlumno.remove(e.id);
                                                  setState(() {});
                                                },
                                              ),
                                              _EstadoChip(
                                                texto: 'FI',
                                                selected: estado == 'FI',
                                                onTap: () {
                                                  asistenciaVM.actualizarEstado(
                                                    e.id,
                                                    'FI',
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                              _EstadoChip(
                                                texto: 'FJ',
                                                selected: estado == 'FJ',
                                                onTap: () {
                                                  asistenciaVM.actualizarEstado(
                                                    e.id,
                                                    'FJ',
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                              _EstadoChip(
                                                texto: 'TI',
                                                selected: estado == 'TI',
                                                onTap: () {
                                                  asistenciaVM.actualizarEstado(
                                                    e.id,
                                                    'TI',
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                              _EstadoChip(
                                                texto: 'TJ',
                                                selected: estado == 'TJ',
                                                onTap: () {
                                                  asistenciaVM.actualizarEstado(
                                                    e.id,
                                                    'TJ',
                                                  );
                                                  setState(() {});
                                                },
                                              ),
                                            ].expand((w) sync* {
                                              yield w;
                                              yield const SizedBox(width: 8);
                                            }).toList()
                                            ..removeLast(),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                Builder(
                                  builder: (_) {
                                    Widget _buildChips(List<String> opciones) {
                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ...opciones.map((op) {
                                            final sel =
                                                _causaPorAlumno[e.id] == op;
                                            return ChoiceChip(
                                              label: Text(op),
                                              selected: sel,
                                              onSelected: (_) {
                                                setState(() {
                                                  _causaPorAlumno[e.id] = op;
                                                });
                                                asistenciaVM.observaciones[e
                                                        .id] =
                                                    op;
                                              },
                                              selectedColor: _primary
                                                  .withOpacity(0.10),
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
                                                _causaPorAlumno[e.id] ==
                                                '__otra__',
                                            onSelected: (_) {
                                              setState(
                                                () =>
                                                    _causaPorAlumno[e.id] =
                                                        '__otra__',
                                              );
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
                                    }

                                    if (estado == 'TJ')
                                      return _buildChips(_causasTJ);
                                    if (estado == 'FJ')
                                      return _buildChips(_causasFJ);
                                    if (estado == 'TI' || estado == 'FI')
                                      return _buildChips(_motivosInjust);
                                    return const SizedBox.shrink();
                                  },
                                ),

                                const SizedBox(height: 10),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: () {
                                    final causa = _causaPorAlumno[e.id];
                                    final est = asistenciaVM.estados[e.id];
                                    final showObs =
                                        est != 'A' &&
                                        ((est == 'TJ' || est == 'FJ')
                                            ? causa == '__otra__'
                                            : true);
                                    if (!showObs) {
                                      return const SizedBox.shrink(
                                        key: ValueKey('hidden'),
                                      );
                                    }
                                    return TextField(
                                      key: const ValueKey('obs'),
                                      decoration: const InputDecoration(
                                        labelText: 'Observación',
                                      ),
                                      onChanged:
                                          (txt) =>
                                              asistenciaVM.observaciones[e.id] =
                                                  txt,
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
                                  items: estudiantes,
                                ),
                            onPanUpdate:
                                (d) => _handleAlphaDrag(
                                  localPos: d.localPosition,
                                  railHeight: railH,
                                  items: estudiantes,
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

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({
    required this.texto,
    required this.selected,
    required this.onTap,
  });

  final String texto;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(texto),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? _primaryDark : Colors.black87,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      side: const BorderSide(color: _outline),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

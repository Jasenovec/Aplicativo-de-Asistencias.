import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/estudiante_viewmodel.dart';
import '../../viewmodels/registro_asistencia_viewmodel.dart';
import '../../models/estudiante.dart';

const _primary = Color(0xFF1E88E5); // Azul 600
const _primaryDark = Color(0xFF1976D2); // Azul 700
const _outline = Color(0xFFE5E7EB); // Gris 200
const _muted = Color(0xFF6B7280); // Gris 500

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

// ⬇️ Cambié a Stateful para manejar búsqueda, scroll y barra alfabética
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

const double _alphaRailW = 24.0; // ancho útil de la barra A–Z
const double _alphaRailPad = 8.0; // respiro a la izquierda de la barra
const double _bottomBarSpace =
    80.0; // espacio que ocupa el botón "Guardar todo"

class _AsistenciaInnerState extends State<_AsistenciaInner> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String _query = '';
  final Map<int, GlobalKey> _itemKeys = {};
  Map<String, int> _letterIndex = {}; // letra -> índice en la lista filtrada

  // --- índice alfabético ---
  bool _isDraggingAlpha = false;
  String _currentLetter = 'A';
  double? _alphaIndicatorDy; // posición Y local del dedo sobre el rail
  final List<String> _letters = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );

  // Causas / motivos
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

  // Estado local: causa/motivo por alumno
  final Map<int, String> _causaPorAlumno = {}; // idEst -> texto o '__otra__'

  bool _validarCausas(RegistroAsistenciaViewModel vm) {
    for (final entry in vm.estados.entries) {
      final id = entry.key;
      final est = entry.value;
      if ((est == 'TJ' || est == 'FJ') && (_causaPorAlumno[id] == null)) {
        return false;
      }
    }
    return true;
  }

  void _onAlphaDrag(
    Offset localPos,
    double railHeight,
    List<Estudiante> items,
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

    _jumpToLetter(letter, items); // ya lo tienes implementado
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
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
    final reservedBottom =
        16 /*top pad*/ +
        48 /*btn height*/ +
        16 /*bottom pad*/ +
        MediaQuery.of(context).padding.bottom; // safe area real
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

    return Theme(
      data: localTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Registrar Asistencia')),
        // Botón Guardar fijo abajo, como en el mockup
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 48,
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
                        // Validación de causas TJ/FJ que ya agregaste
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
                          await asistenciaVM
                              .registrarTodo(); // muestra "Guardando..." lo que deba

                          if (!mounted) return;
                          // ✅ Modal centrado (check verde)
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
                                        size: 50.0,
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
                          // ⬅️ Volver al Home (pantalla raíz)
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        } catch (e) {
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
            // Cabecera: grado/sección + fecha
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
                          fontSize: 16.0,
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
                        style: const TextStyle(color: _muted, fontSize: 16.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Buscador
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
                      16 +
                          _alphaRailW +
                          _alphaRailPad, // deja canal para la barra A–Z
                      reservedBottom, // respeta el área del botón
                    ),
                    itemCount: estudiantes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final Estudiante e = estudiantes[i];
                      _itemKeys.putIfAbsent(e.id, () => GlobalKey());
                      asistenciaVM.estados.putIfAbsent(
                        e.id,
                        () => 'A',
                      ); // default
                      final estado = asistenciaVM.estados[e.id];
                      _itemKeys.putIfAbsent(e.id, () => GlobalKey());
                      asistenciaVM.estados.putIfAbsent(
                        e.id,
                        () => 'A',
                      ); // default
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
                                const SizedBox(height: 8),

                                // ====== ESTADO (A/FI/FJ/TI/TJ) ======
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
                                            asistenciaVM.actualizarEstado(
                                              e.id,
                                              s,
                                            );
                                            if (s == 'A') {
                                              FocusScope.of(context).unfocus();
                                              asistenciaVM.observaciones.remove(
                                                e.id,
                                              ); // limpia obs
                                              _causaPorAlumno.remove(
                                                e.id,
                                              ); // limpia causa
                                            }
                                            setState(
                                              () {},
                                            ); // refresca UI dependiente
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

                                // ====== CAUSAS / MOTIVOS según estado ======
                                const SizedBox(height: 8),

                                Builder(
                                  builder: (_) {
                                    // helper local para dibujar chips de causa/motivo
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
                                                // Si quieres que la causa quede también en observaciones:
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
                                              // No tocamos observaciones; el usuario la escribe
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

                                    if (estado == 'TJ') {
                                      return _buildChips(_causasTJ);
                                    } else if (estado == 'FJ') {
                                      return _buildChips(_causasFJ);
                                    } else if (estado == 'TI' ||
                                        estado == 'FI') {
                                      return _buildChips(_motivosInjust);
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),

                                const SizedBox(height: 10),

                                // ====== OBSERVACIÓN: regla de visibilidad ======
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  child: () {
                                    // muestra obs si NO es A y:
                                    // - TJ/FJ -> solo cuando eligió "Otra…"
                                    // - TI/FI -> siempre opcional
                                    final causa = _causaPorAlumno[e.id];
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

                  // Barra alfabética a la derecha (A–Z)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: reservedBottom - 10, // se detiene antes del botón
                    child: SizedBox(
                      width: _alphaRailW + _alphaRailPad,
                      child: LayoutBuilder(
                        builder: (ctx, cons) {
                          final railH = cons.maxHeight;
                          final cellH = railH / _letters.length;
                          final fontSize = (cellH * 0.75).clamp(10.0, 14.0);

                          return GestureDetector(
                            behavior:
                                HitTestBehavior
                                    .opaque, // captura todo el dedo en el rail
                            onPanDown:
                                (d) => _onAlphaDrag(
                                  d.localPosition,
                                  railH,
                                  estudiantes,
                                ),
                            onPanUpdate:
                                (d) => _onAlphaDrag(
                                  d.localPosition,
                                  railH,
                                  estudiantes,
                                ),
                            onPanEnd:
                                (_) => setState(() => _isDraggingAlpha = false),
                            onPanCancel:
                                () => setState(() => _isDraggingAlpha = false),
                            child: Stack(
                              children: [
                                // Línea guía
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

                                // Letras A–Z distribuidas (rail fijo, no se mueve)
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

                                // Pestañita con la letra actual (aparece mientras arrastras)
                                if (_isDraggingAlpha)
                                  Positioned(
                                    right: _alphaRailW + 8,
                                    top: ((_alphaIndicatorDy ?? railH / 2) - 22)
                                        .clamp(0.0, railH - 44),
                                    child: _AlphaBubble(letter: _currentLetter),
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
  const _AlphaBubble({required this.letter});
  final String letter;

  @override
  Widget build(BuildContext context) {
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
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _primaryDark,
          ),
        ),
      ),
    );
  }
}

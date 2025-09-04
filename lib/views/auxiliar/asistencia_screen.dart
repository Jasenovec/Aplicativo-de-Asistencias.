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

// ⬇️ Cambié a Stateful para manejar búsqueda, scroll y barra alfabética
class _AsistenciaInner extends StatefulWidget {
  const _AsistenciaInner({required this.grado, required this.seccion});
  final int grado;
  final int seccion;

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
                  asistenciaVM.isLoading ? null : asistenciaVM.registrarTodo,
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
                        'Grado: ${widget.grado} º • Sección: ${widget.seccion}',
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
                                // Selector de estado con chips (rápido de tocar)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      ['A', 'FI', 'FJ', 'TI', 'TJ'].map((s) {
                                        final selected =
                                            asistenciaVM.estados[e.id] == s;
                                        return ChoiceChip(
                                          label: Text(s),
                                          selected: selected,
                                          onSelected:
                                              (_) => asistenciaVM
                                                  .actualizarEstado(e.id, s),
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
                                const SizedBox(height: 10),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Observación',
                                  ),
                                  onChanged:
                                      (txt) =>
                                          asistenciaVM.observaciones[e.id] =
                                              txt,
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
                    bottom: reservedBottom - 35, // se detiene antes del botón
                    child: SizedBox(
                      width: _alphaRailW + _alphaRailPad,
                      child: Stack(
                        children: [
                          // Línea guía
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              color: _outline,
                            ),
                          ),
                          // Letras A–Z scrollable
                          Align(
                            alignment: Alignment.centerRight,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              physics: const BouncingScrollPhysics(),
                              itemCount: 28,
                              itemExtent:
                                  20, // altura fija por letra (ajusta 14–18 si quieres)
                              itemBuilder: (_, i) {
                                final letter = String.fromCharCode(65 + i);
                                final active = _letterIndex.containsKey(letter);
                                return GestureDetector(
                                  onTap:
                                      active
                                          ? () =>
                                              _jumpToLetter(letter, estudiantes)
                                          : null,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            active
                                                ? _primaryDark
                                                : _muted.withOpacity(0.35),
                                        fontWeight:
                                            active
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

// lib/screens/home_screen.dart
import 'dart:async';
import 'package:asistencia_app/utils/calendar_rules.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _timeString = "";
  String _dateString = "";

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Timer _clockTimer;

  bool get _hoyNoLaborable => CalendarRules.esNoLaborable(DateTime.now());

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeString = DateFormat('HH:mm:ss').format(now);
      _dateString = DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(now);
    });
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _onAsistenciaTap(VoidCallback nav) async {
    if (_hoyNoLaborable) {
      await showNoLaborableMessage(context);
      return;
    }
    nav();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disabled = _hoyNoLaborable;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 11, 114, 204),
                  Color.fromARGB(255, 183, 199, 229),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            top: true,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 35),
                    Image.asset(
                      "assets/images/logo_colegio.png",
                      height: 180,
                      width: 180,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "¡Bienvenido!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Sistema de Control de Asistencias",
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _timeString,
                      style: const TextStyle(
                        fontSize: 58,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _dateString,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Desde aquí puedes registrar asistencias de los estudiantes "
                        "y consultar las asistencias ya registradas.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Menú
                    _MenuCard(
                      icon: Icons.playlist_add_check,
                      label: "Registrar Asistencia",
                      color: Colors.greenAccent,
                      enabled: !disabled,
                      onTap:
                          () => _onAsistenciaTap(
                            () => Navigator.pushNamed(context, '/seleccionar'),
                          ),
                    ),
                    const SizedBox(height: 14),
                    _MenuCard(
                      icon: Icons.list,
                      label: "Modificar Asistencia",
                      color: Colors.orangeAccent,
                      enabled: !disabled,
                      onTap:
                          () => _onAsistenciaTap(
                            () => Navigator.pushNamed(
                              context,
                              '/ver_asistencias',
                            ),
                          ),
                    ),
                    const SizedBox(height: 10),
                    if (disabled)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Hoy no hay clases (día no laborable).',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Botón rojo /home
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, top: 8),
                child: _SquareIconButton(
                  onTap: _goHome,
                  tooltip: 'Cerrar sesión',
                  background: const Color(0xFFD7330A),
                  borderColor: const Color(0xFFD7330A),
                  iconColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final String tooltip;
  final Color background;
  final Color borderColor;
  final Color iconColor;
  const _SquareIconButton({
    required this.onTap,
    required this.tooltip,
    required this.background,
    required this.borderColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              child: Icon(Icons.logout, color: iconColor, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GestureDetector(
        onTapDown: (_) {
          if (!disabled) setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          if (!disabled) {
            setState(() => _isPressed = false);
            widget.onTap();
          } else {
            showNoLaborableMessage(context);
          }
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          curve: Curves.easeOut,
          height: 56,
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow:
                _isPressed
                    ? []
                    : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 28, color: widget.color),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

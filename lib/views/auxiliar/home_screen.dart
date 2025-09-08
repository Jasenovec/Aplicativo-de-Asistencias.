import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
      duration: const Duration(milliseconds: 900),
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

  // "Cerrar sesión" -> lleva a /home y borra el historial
  void _logout() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Fondo
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

          // Contenido
          SafeArea(
            top: true,
            bottom: true, // evita que la nav bar tape los botones
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Image.asset(
                      "assets/images/logo_colegio.png",
                      height: 190,
                      width: 190,
                    ),

                    const SizedBox(height: 12),

                    // Títulos
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

                    // Reloj y fecha
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

                    // Descripción
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

                    // Opciones (más arriba y con tamaños prudentes)
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: Column(
                        children: [
                          _MenuCard(
                            icon: Icons.playlist_add_check,
                            label: "Registrar Asistencia",
                            color: Colors.greenAccent,
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  '/seleccionar',
                                ),
                          ),
                          const SizedBox(height: 14),
                          _MenuCard(
                            icon: Icons.list,
                            label: "Modificar Asistencia",
                            color: Colors.orangeAccent,
                            onTap:
                                () => Navigator.pushNamed(
                                  context,
                                  '/ver_asistencias',
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Pequeño respiro inferior, pero sin empujar demasiado
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Botón rojo "cerrar sesión / ir a /home" (esquina superior izquierda)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 14, top: 8),
                child: _SquareIconButton(
                  onTap: _logout,
                  tooltip: 'Cerrar sesión',
                  background: const Color(0xFFD7330A), // rojo solicitado
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

// Botón cuadrado con bordes redondeados y el ícono de "salir" mirando a la izquierda
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

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        curve: Curves.easeOut,
        height: 56, // un poco más compacto
        width: 300, // ancho mayor pero moderado
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

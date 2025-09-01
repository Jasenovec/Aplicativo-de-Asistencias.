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

  @override
  void initState() {
    super.initState();
    _updateTime();
    Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());

    // Animación de entrada
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 📌 Imagen del logo de asistencia
                  Image.asset(
                    "assets/images/logo_colegio.png",
                    height: 140,
                    width: 140,
                  ),

                  const SizedBox(height: 20),

                  // Texto de bienvenida
                  const Text(
                    "¡Bienvenido!",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sistema de Control de Asistencias",
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),

                  const SizedBox(height: 30),

                  // Reloj y fecha
                  Column(
                    children: [
                      Text(
                        _timeString,
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _dateString,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Descripción
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      "Desde aquí puedes registrar asistencias de los estudiantes "
                      "y consultar las asistencias ya registradas.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                  ),

                  const Spacer(),

                  // Opciones
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(_fadeAnimation),
                    child: Column(
                      children: [
                        _MenuCard(
                          icon: Icons.playlist_add_check,
                          label: "Registrar Asistencia",
                          color: Colors.greenAccent,
                          onTap:
                              () =>
                                  Navigator.pushNamed(context, '/seleccionar'),
                        ),
                        const SizedBox(height: 30),
                        _MenuCard(
                          icon: Icons.list,
                          label: "Ver Asistencias Registradas",
                          color: Colors.orangeAccent,
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                '/ver_asistencias',
                              ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
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
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        height: 60,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow:
              _isPressed
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 32, color: widget.color),
            const SizedBox(width: 15),
            Text(
              widget.label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}



      // extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   title: const Text(
      //     'MENÚ AUXILIAR',
      //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
      //   ),
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: const Icon(Icons.home, color: Colors.white),
      //     onPressed: () {
      //       Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      //     },
      //   ),
      // ),
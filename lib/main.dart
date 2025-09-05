import 'package:asistencia_app/core/auth_store.dart';
import 'package:asistencia_app/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth_token_storage.dart';
import 'core/api_config.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/asistencia_viewmodel.dart';

import 'views/splash/splash_screen.dart';
import 'views/login/login_screen.dart';
import 'views/auxiliar/home_screen.dart';
import 'views/auxiliar/seleccionar_grado_seccion_screen.dart';
import 'views/auxiliar/seleccionar_grado_seccion_fecha_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_PE', null);

  ApiConfig.attachAuthInterceptor(
    getToken: AuthStore.getToken,
    onUnauthorized: () {
      AuthStore.clear();
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (r) => false,
      );
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthTokenStorage(), AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => AsistenciaViewModel(estudianteVM: null),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Asistencia Escolar',

        // 👇👇 AQUI VA EL THEME
        theme: AppTheme.light(), // <- usa tu ThemeData global
        // (opcional) si luego haces un dark:
        // darkTheme: AppTheme.dark(),
        // themeMode: ThemeMode.light,

        // 👇 recomendado porque usas NavigationService en el interceptor
        navigatorKey: NavigationService.navigatorKey,

        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/': (context) => const HomeScreen(),
          '/seleccionar': (context) => const SeleccionarGradoSeccionScreen(),
          '/ver_asistencias':
              (context) => const SeleccionarGradoSeccionFechaScreen(),
        },
      ),
    );
  }
}




  // @override
  // Widget build(BuildContext context) {
  //   return ChangeNotifierProvider(
  //     create: (_) => AsistenciaViewModel(estudianteVM: null),
  //     child: MaterialApp(
  //       debugShowCheckedModeBanner: false,
  //       title: 'Asistencia Escolar',
  //       initialRoute: '/',
  //       routes: {'/': (context) => const HomeScreen()},
  //     ),
  //   );
  // }
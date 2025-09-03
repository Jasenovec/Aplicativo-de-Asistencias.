import 'package:dio/dio.dart';

/// Configuración de la API para realizar peticiones HTTP
/// Utiliza Dio para manejar las solicitudes y respuestas
class ApiConfig {
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000', // cambia IP según tu red
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

//192.168.0.192
//92.168.10.96 SOLMAR
//10.0.2.2 EMULADOR

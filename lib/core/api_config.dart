import 'package:dio/dio.dart';

/// Configuración de la API para realizar peticiones HTTP
/// Utiliza Dio para manejar las solicitudes y respuestas
class ApiConfig {
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.10.79:3000', // cambia IP según tu red
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

//192.168.0.192

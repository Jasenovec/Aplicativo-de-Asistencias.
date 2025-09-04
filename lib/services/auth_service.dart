import 'package:dio/dio.dart';
import '../core/api_config.dart';
import '../models/auth_models.dart';

class AuthService {
  Future<AuthSession> login(String usuario, String password) async {
    final res = await ApiConfig.dio.post(
      '/auth/login',
      data: {'usuario': usuario, 'password': password},
    );
    return AuthSession.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthUser> me() async {
    final Response res = await ApiConfig.dio.get('/auth/me');
    return AuthUser.fromJson(res.data as Map<String, dynamic>);
  }
}

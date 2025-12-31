import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/auth_token_storage.dart';
import '../core/api_config.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthTokenStorage _storage;
  final AuthService _service;

  String? _token;
  AuthUser? _user;

  AuthViewModel(this._storage, this._service) {
    ApiConfig.attachAuthInterceptor(
      getToken: () async => _token ?? await _storage.read(),
      onUnauthorized: logout,
    );
  }

  String? get token => _token;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);

  Future<void> initialize() async {
    _token = await _storage.read();
    if (_token == null) return;

    if (JwtDecoder.isExpired(_token!)) {
      await logout();
      return;
    }

    try {
      _user = await _service.me();
    } catch (_) {
      await logout();
    }
    notifyListeners();
  }

  Future<bool> login(String usuario, String password) async {
    final session = await _service.login(usuario, password);
    _token = session.token;
    await _storage.save(session.token);
    try {
      _user = await _service.me();
    } catch (_) {
      _user = session.user;
    }
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.clear();
    notifyListeners();
  }
}

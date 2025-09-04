import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStorage {
  static const _k = 'jwt_token';
  final FlutterSecureStorage _s = const FlutterSecureStorage();

  Future<void> save(String token) => _s.write(key: _k, value: token);
  Future<String?> read() => _s.read(key: _k);
  Future<void> clear() => _s.delete(key: _k);
}

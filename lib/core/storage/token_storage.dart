import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'jwt_token';
  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  Future<void> write(String token) => _storage.write(key: _key, value: token);
  Future<String?> read() => _storage.read(key: _key);
  Future<void> clear() => _storage.delete(key: _key);
}

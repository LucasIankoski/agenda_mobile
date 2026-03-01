import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  final ApiClient _client;
  final TokenStorage _tokenStorage;

  AuthRepository(this._client, this._tokenStorage);

  Future<AuthResponse> login(LoginRequest req) async {
    try {
      final res = await _client.dio.post('/auth/login', data: req.toJson());
      final data = (res.data as Map).cast<String, dynamic>();
      final auth = AuthResponse.fromJson(data);
      await _tokenStorage.write(auth.token);
      return auth;
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<AuthResponse> register(RegisterRequest req) async {
    try {
      final res = await _client.dio.post('/auth/register', data: req.toJson());
      final data = (res.data as Map).cast<String, dynamic>();
      final auth = AuthResponse.fromJson(data);
      await _tokenStorage.write(auth.token);
      return auth;
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<String?> getToken() => _tokenStorage.read();

  Future<void> logout() => _tokenStorage.clear();
}

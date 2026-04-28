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

  Future<List<LoginSchoolOption>> listLoginSchools() async {
    try {
      final res = await _client.dio.get('/auth/schools');
      final data = res.data;
      if (data is List) {
        return data.map(_toLoginSchoolOption).where((school) => school.slug.isNotEmpty).toList();
      }
      throw AppException('Formato de resposta invalido ao carregar escolas.');
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Falha ao interpretar as escolas.', cause: e);
    }
  }

  Future<String?> getToken() => _tokenStorage.read();

  Future<void> logout() => _tokenStorage.clear();

  LoginSchoolOption _toLoginSchoolOption(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return LoginSchoolOption.fromJson(raw);
    }
    if (raw is Map) {
      return LoginSchoolOption.fromJson(raw.cast<String, dynamic>());
    }
    throw AppException('Item de escola em formato invalido.');
  }
}

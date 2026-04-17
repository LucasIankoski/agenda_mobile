import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import 'user_model.dart';

class UserRepository {
  final ApiClient _client;

  UserRepository(this._client);

  Future<List<ManagedUser>> list() async {
    try {
      final res = await _client.dio.get('/api/v1/users');
      return _parseUserList(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar os usuarios cadastrados.', cause: e);
    }
  }

  Future<ManagedUser> get(String id) async {
    try {
      final res = await _client.dio.get('/api/v1/users/$id');
      return _toManagedUser(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar os dados do usuario.', cause: e);
    }
  }

  Future<ManagedUser> disable(String id) async {
    try {
      final res = await _client.dio.patch('/api/v1/users/$id/desativar');
      return _toManagedUser(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar a desativacao do usuario.', cause: e);
    }
  }

  List<ManagedUser> _parseUserList(dynamic data) {
    if (data == null) return const [];
    if (data is List) {
      return data.map(_toManagedUser).toList();
    }

    if (data is Map) {
      const listKeys = ['content', 'items', 'data', 'users', 'results'];
      for (final key in listKeys) {
        final nested = data[key];
        if (nested is List) {
          return nested.map(_toManagedUser).toList();
        }
      }
    }

    throw AppException('Formato de resposta invalido ao carregar usuarios.');
  }

  ManagedUser _toManagedUser(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ManagedUser.fromJson(raw);
    }
    if (raw is Map) {
      return ManagedUser.fromJson(raw.cast<String, dynamic>());
    }
    throw AppException('Item de usuario em formato invalido.');
  }
}

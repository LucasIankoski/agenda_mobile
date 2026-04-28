import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import 'school_model.dart';

class PlatformRepository {
  final ApiClient _client;

  PlatformRepository(this._client);

  Future<List<ManagedSchool>> listSchools() async {
    try {
      final res = await _client.dio.get('/api/v1/platform/schools');
      return _parseSchoolList(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar as escolas cadastradas.', cause: e);
    }
  }

  Future<ManagedSchool> createSchool(PlatformSchoolCreateRequest request) async {
    try {
      final res = await _client.dio.post('/api/v1/platform/schools', data: request.toJson());
      final data = (res.data as Map).cast<String, dynamic>();
      final school = data['school'];
      if (school is Map<String, dynamic>) return ManagedSchool.fromJson(school);
      if (school is Map) return ManagedSchool.fromJson(school.cast<String, dynamic>());
      return ManagedSchool.fromJson(data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar a escola criada.', cause: e);
    }
  }

  Future<void> createAdmin(String schoolId, SchoolAdminCreateRequest request) async {
    try {
      await _client.dio.post('/api/v1/platform/schools/$schoolId/admins', data: request.toJson());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  List<ManagedSchool> _parseSchoolList(dynamic data) {
    if (data == null) return const [];
    if (data is List) {
      return data.map(_toSchool).toList();
    }

    if (data is Map) {
      const listKeys = ['content', 'items', 'data', 'schools', 'results'];
      for (final key in listKeys) {
        final nested = data[key];
        if (nested is List) {
          return nested.map(_toSchool).toList();
        }
      }
    }

    throw AppException('Formato de resposta invalido ao carregar escolas.');
  }

  ManagedSchool _toSchool(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ManagedSchool.fromJson(raw);
    }
    if (raw is Map) {
      return ManagedSchool.fromJson(raw.cast<String, dynamic>());
    }
    throw AppException('Item de escola em formato invalido.');
  }
}

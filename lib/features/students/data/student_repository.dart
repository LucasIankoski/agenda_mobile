import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import 'student_model.dart';

class StudentRepository {
  final ApiClient _client;
  StudentRepository(this._client);

  Future<List<Student>> list() async {
    try {
      final res = await _client.dio.get('/api/v1/students');
      return _parseStudentListResponse(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar a lista de alunos.', cause: e);
    }
  }

  Future<List<Student>> listByClassroom(String classroomId) async {
    try {
      final res = await _client.dio.get('/api/v1/classrooms/$classroomId/students');
      return _parseStudentListResponse(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar os alunos da turma.', cause: e);
    }
  }

  Future<Student?> getByResponsible({String? login}) async {
    try {
      final query = <String, dynamic>{};
      if (login != null && login.trim().isNotEmpty) {
        query['login'] = login.trim();
      }

      final res = await _client.dio.get('/api/v1/students/by-responsible', queryParameters: query);
      return _toStudent(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar o aluno vinculado ao responsavel.', cause: e);
    }
  }

  Future<Student> get(String id) async {
    try {
      final res = await _client.dio.get('/api/v1/students/$id');
      return Student.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar os dados do aluno.', cause: e);
    }
  }

  Future<Student> create(StudentCreateRequest req) async {
    try {
      final res = await _client.dio.post('/api/v1/students', data: req.toJson());
      return Student.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar o aluno criado.', cause: e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _client.dio.delete('/api/v1/students/$id');
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  List<Student> _parseStudentListResponse(dynamic data) {
    final rawItems = _extractStudentItems(data);
    return rawItems.map(_toStudent).toList();
  }

  List<dynamic> _extractStudentItems(dynamic data) {
    if (data == null) return const [];
    if (data is List) return data;

    if (data is Map) {
      const listKeys = ['content', 'items', 'data', 'students', 'results'];
      for (final key in listKeys) {
        final nested = data[key];
        if (nested is List) return nested;
      }

      final looksLikeSingleStudent = data.containsKey('id') || data.containsKey('name') || data.containsKey('lastName');
      if (looksLikeSingleStudent) {
        return [data];
      }
    }

    throw AppException('Formato de resposta invalido ao carregar alunos.');
  }

  Student _toStudent(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return Student.fromJson(raw);
    }
    if (raw is Map) {
      return Student.fromJson(raw.cast<String, dynamic>());
    }
    throw AppException('Item de aluno em formato invalido.');
  }
}

import 'package:dio/dio.dart';

import '../../../core/http/api_client.dart';
import 'student_model.dart';

class StudentRepository {
  final ApiClient _client;
  StudentRepository(this._client);

  Future<List<Student>> list() async {
    try {
      final res = await _client.dio.get('/api/v1/students');
      final list = (res.data as List).cast<Map>();
      return list.map((e) => Student.fromJson(e.cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<List<Student>> listByClassroom(String classroomId) async {
    try {
      final res = await _client.dio.get('/api/v1/classrooms/$classroomId/students');
      final list = (res.data as List).cast<Map>();
      return list.map((e) => Student.fromJson(e.cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<Student> get(String id) async {
    try {
      final res = await _client.dio.get('/api/v1/students/$id');
      return Student.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<Student> create(StudentCreateRequest req) async {
    try {
      final res = await _client.dio.post('/api/v1/students', data: req.toJson());
      return Student.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _client.dio.delete('/api/v1/students/$id');
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }
}

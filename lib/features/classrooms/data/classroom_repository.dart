import 'package:dio/dio.dart';

import '../../../core/http/api_client.dart';
import 'classroom_model.dart';

class ClassroomRepository {
  final ApiClient _client;
  ClassroomRepository(this._client);

  Future<List<Classroom>> list() async {
    try {
      final res = await _client.dio.get('/api/v1/classrooms');
      final list = (res.data as List).cast<Map>();
      return list.map((e) => Classroom.fromJson(e.cast<String, dynamic>())).toList();
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<Classroom> get(String id) async {
    try {
      final res = await _client.dio.get('/api/v1/classrooms/$id');
      return Classroom.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<Classroom> create(ClassroomCreateRequest req) async {
    try {
      final res = await _client.dio.post('/api/v1/classrooms', data: req.toJson());
      return Classroom.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<Classroom> update(String id, ClassroomUpdateRequest req) async {
    try {
      final res = await _client.dio.put('/api/v1/classrooms/$id', data: req.toJson());
      return Classroom.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<void> remove(String id) async {
    try {
      await _client.dio.delete('/api/v1/classrooms/$id');
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }
}

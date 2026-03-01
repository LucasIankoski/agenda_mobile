import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import 'diary_models.dart';

class DiaryRepository {
  final ApiClient _client;
  DiaryRepository(this._client);

  List<Map<String, dynamic>> _extractDiaryList(dynamic data) {
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }

    if (data is! Map) return const [];

    final map = data.cast<String, dynamic>();

    final content = map['content'];
    if (content is List) {
      return content.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }

    final embedded = map['_embedded'];
    if (embedded is Map) {
      for (final value in embedded.values) {
        if (value is List) {
          return value.map((e) => (e as Map).cast<String, dynamic>()).toList();
        }
      }
    }

    return const [];
  }

  int _readInt(Map<String, dynamic> map, String key, int fallback) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return fallback;
  }

  List<Diary> _parseDiaries(List<Map<String, dynamic>> items) {
    final diaries = <Diary>[];
    for (final item in items) {
      try {
        diaries.add(Diary.fromJson(item));
      } catch (e, st) {
        debugPrint('DiaryRepository._parseDiaries item parse failed: $e');
        debugPrint('DiaryRepository._parseDiaries item payload: $item');
        debugPrint('$st');
      }
    }
    return diaries;
  }

  Future<void> create(DiaryCreateRequest req) async {
    try {
      await _client.dio.post('/api/v2/diaries', data: req.toJson());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<Diary> get(String id) async {
    try {
      final res = await _client.dio.get('/api/v2/diaries/$id');
      return Diary.fromJson((res.data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  Future<PageResult<Diary>> listByStudent(String studentId, {int page = 0, int size = 10}) async {
    try {
      final res = await _client.dio.get(
        '/api/v2/diaries/student/$studentId',
        queryParameters: {'page': page, 'size': size},
      );

      final raw = res.data;
      debugPrint('DiaryRepository.listByStudent raw response: $raw');
      final map = raw is Map ? raw.cast<String, dynamic>() : <String, dynamic>{};
      final items = _extractDiaryList(raw);
      debugPrint('DiaryRepository.listByStudent extracted items: ${items.length}');
      final diaries = _parseDiaries(items);
      debugPrint('DiaryRepository.listByStudent parsed diaries: ${diaries.length}');
      final pageInfo = map['page'] is Map ? (map['page'] as Map).cast<String, dynamic>() : <String, dynamic>{};
      final totalPages = _readInt(map, 'totalPages', _readInt(pageInfo, 'totalPages', diaries.isEmpty ? 0 : 1));

      return PageResult(
        items: diaries,
        page: _readInt(map, 'number', _readInt(pageInfo, 'number', page)),
        size: _readInt(map, 'size', _readInt(pageInfo, 'size', size)),
        totalPages: totalPages <= 0 ? 1 : totalPages,
        totalElements: _readInt(map, 'totalElements', _readInt(pageInfo, 'totalElements', diaries.length)),
      );
    } on DioException catch (e) {
      debugPrint('DiaryRepository.listByStudent dio error: ${e.message}');
      debugPrint('DiaryRepository.listByStudent dio response: ${e.response?.data}');
      throw _client.mapDioError(e);
    } catch (e, st) {
      debugPrint('DiaryRepository.listByStudent unexpected error: $e');
      debugPrint('$st');
      throw AppException('Falha ao processar a lista de diarios.');
    }
  }
}

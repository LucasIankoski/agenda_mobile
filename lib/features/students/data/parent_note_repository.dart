import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import 'parent_note_model.dart';

class ParentNoteRepository {
  final ApiClient _client;

  ParentNoteRepository(this._client);

  Future<List<ParentNote>> listByStudent(String studentId) async {
    try {
      final res = await _client.dio.get('/api/v1/students/$studentId/parent-notes');
      return _parseParentNoteListResponse(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar os recados do aluno.', cause: e);
    }
  }

  Future<ParentNote> create(String studentId, ParentNoteCreateRequest req) async {
    try {
      final res = await _client.dio.post('/api/v1/students/$studentId/parent-notes', data: req.toJson());
      return _toParentNote(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar o recado enviado.', cause: e);
    }
  }

  Future<void> markAllAsRead(String studentId) async {
    try {
      await _client.dio.post('/api/v1/students/$studentId/parent-notes/mark-read');
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    }
  }

  List<ParentNote> _parseParentNoteListResponse(dynamic data) {
    if (data == null) return const [];
    if (data is List) {
      return data.map(_toParentNote).toList();
    }

    if (data is Map) {
      const listKeys = ['content', 'items', 'data', 'notes', 'parentNotes', 'results'];
      for (final key in listKeys) {
        final nested = data[key];
        if (nested is List) {
          return nested.map(_toParentNote).toList();
        }
      }
    }

    throw AppException('Formato de resposta inválido ao carregar recados.');
  }

  ParentNote _toParentNote(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return ParentNote.fromJson(raw);
    }
    if (raw is Map) {
      return ParentNote.fromJson(raw.cast<String, dynamic>());
    }
    throw AppException('Item de recado em formato inválido.');
  }
}

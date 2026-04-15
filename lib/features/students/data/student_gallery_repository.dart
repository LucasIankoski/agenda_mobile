import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/api_client.dart';
import 'student_gallery_model.dart';

class StudentGalleryRepository {
  final ApiClient _client;

  StudentGalleryRepository(this._client);

  Future<List<StudentGalleryPhoto>> listByStudent(String studentId) async {
    try {
      final res = await _client.dio.get('/api/v1/students/$studentId/gallery');
      return _parseGalleryListResponse(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao interpretar a galeria do aluno.', cause: e);
    }
  }

  Future<List<StudentGalleryPhoto>> create(
    String studentId, {
    required List<XFile> files,
    String? caption,
  }) async {
    if (files.isEmpty) return const [];

    try {
      final formData = FormData();
      final cleanCaption = caption?.trim();
      if (cleanCaption != null && cleanCaption.isNotEmpty) {
        formData.fields.add(MapEntry('caption', cleanCaption));
      }

      final multipartFiles = await Future.wait(files.map(_toMultipartFile));
      for (final file in multipartFiles) {
        formData.files.add(MapEntry('files', file));
      }

      final res = await _client.dio.post('/api/v1/students/$studentId/gallery', data: formData);
      return _parseGalleryListResponse(res.data);
    } on DioException catch (e) {
      throw _client.mapDioError(e);
    } catch (e) {
      throw AppException('Falha ao enviar as fotos da galeria.', cause: e);
    }
  }

  List<StudentGalleryPhoto> _parseGalleryListResponse(dynamic data) {
    if (data == null) return const [];
    if (data is List) {
      return data.map(_toStudentGalleryPhoto).toList();
    }

    if (data is Map) {
      const listKeys = ['content', 'items', 'data', 'photos', 'gallery', 'results'];
      for (final key in listKeys) {
        final nested = data[key];
        if (nested is List) {
          return nested.map(_toStudentGalleryPhoto).toList();
        }
      }
    }

    throw AppException('Formato de resposta invalido ao carregar a galeria.');
  }

  StudentGalleryPhoto _toStudentGalleryPhoto(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return StudentGalleryPhoto.fromJson(raw);
    }
    if (raw is Map) {
      return StudentGalleryPhoto.fromJson(raw.cast<String, dynamic>());
    }
    throw AppException('Item da galeria em formato invalido.');
  }

  Future<MultipartFile> _toMultipartFile(XFile file) async {
    final fileName = file.name.trim().isEmpty ? 'foto.jpg' : file.name;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return MultipartFile.fromBytes(bytes, filename: fileName);
    }
    return MultipartFile.fromFile(file.path, filename: fileName);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/student_gallery_model.dart';
import '../data/student_gallery_repository.dart';

final studentGalleryRepositoryProvider = Provider<StudentGalleryRepository>((ref) {
  return StudentGalleryRepository(ref.watch(apiClientProvider));
});

final studentGalleryByStudentProvider =
    FutureProvider.family<List<StudentGalleryPhoto>, String>((ref, studentId) async {
  return ref.read(studentGalleryRepositoryProvider).listByStudent(studentId);
});

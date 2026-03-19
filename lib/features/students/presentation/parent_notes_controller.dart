import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/parent_note_model.dart';
import '../data/parent_note_repository.dart';

final parentNoteRepositoryProvider = Provider<ParentNoteRepository>((ref) {
  return ParentNoteRepository(ref.watch(apiClientProvider));
});

final parentNotesByStudentProvider = FutureProvider.family<List<ParentNote>, String>((ref, studentId) async {
  return ref.read(parentNoteRepositoryProvider).listByStudent(studentId);
});

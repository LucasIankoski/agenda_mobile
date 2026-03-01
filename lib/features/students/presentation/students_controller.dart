import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/student_model.dart';
import '../data/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.watch(apiClientProvider));
});

final studentsProvider = AsyncNotifierProvider<StudentsController, List<Student>>(StudentsController.new);
final studentsByClassroomProvider = FutureProvider.family<List<Student>, String>((ref, classroomId) async {
  return ref.read(studentRepositoryProvider).listByClassroom(classroomId);
});

class StudentsController extends AsyncNotifier<List<Student>> {
  @override
  Future<List<Student>> build() async {
    return ref.read(studentRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(studentRepositoryProvider).list());
  }
}

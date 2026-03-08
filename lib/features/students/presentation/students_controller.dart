import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../../auth/presentation/auth_controller.dart';
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
    ref.watch(authControllerProvider);
    return _loadVisibleStudents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadVisibleStudents);
  }

  Future<List<Student>> _loadVisibleStudents() async {
    final isAuthenticated = ref.read(authControllerProvider).valueOrNull?.isAuthenticated == true;
    if (!isAuthenticated) {
      return const [];
    }

    // O backend aplica a regra por perfil (ADMIN/PROFESSOR veem todos; PAI ve apenas vinculados).
    return ref.read(studentRepositoryProvider).list();
  }
}

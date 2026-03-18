import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/classroom_model.dart';
import '../data/classroom_repository.dart';

final classroomRepositoryProvider = Provider<ClassroomRepository>((ref) {
  return ClassroomRepository(ref.watch(apiClientProvider));
});

final classroomDetailProvider = FutureProvider.family<Classroom, String>((ref, id) async {
  return ref.read(classroomRepositoryProvider).get(id);
});

final classroomsProvider = AsyncNotifierProvider<ClassroomsController, List<Classroom>>(ClassroomsController.new);

class ClassroomsController extends AsyncNotifier<List<Classroom>> {
  @override
  Future<List<Classroom>> build() async {
    return ref.read(classroomRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(classroomRepositoryProvider).list());
  }
}

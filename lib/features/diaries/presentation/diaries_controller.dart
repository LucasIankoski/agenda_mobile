import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/diary_models.dart';
import '../data/diary_repository.dart';

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.watch(apiClientProvider));
});

final diariesControllerProvider = AsyncNotifierProviderFamily<DiariesController, PageResult<Diary>, String>(DiariesController.new);

class DiariesController extends FamilyAsyncNotifier<PageResult<Diary>, String> {
  late String studentId;

  @override
  Future<PageResult<Diary>> build(String studentId) async {
    this.studentId = studentId;
    return ref.read(diaryRepositoryProvider).listByStudent(studentId);
  }

  Future<void> load(int page) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(diaryRepositoryProvider).listByStudent(studentId, page: page));
  }
}

final diariesByStudentProvider = Provider.family<AsyncValue<PageResult<Diary>>, String>((ref, studentId) {
  return ref.watch(diariesControllerProvider(studentId));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/platform_repository.dart';
import '../data/school_model.dart';

final platformRepositoryProvider = Provider<PlatformRepository>((ref) {
  return PlatformRepository(ref.watch(apiClientProvider));
});

final schoolsProvider = AsyncNotifierProvider<SchoolsController, List<ManagedSchool>>(SchoolsController.new);

class SchoolsController extends AsyncNotifier<List<ManagedSchool>> {
  @override
  Future<List<ManagedSchool>> build() async {
    return ref.read(platformRepositoryProvider).listSchools();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(platformRepositoryProvider).listSchools());
  }
}

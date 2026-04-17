import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/http/di_providers.dart';
import '../data/user_model.dart';
import '../data/user_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(apiClientProvider));
});

final usersProvider = AsyncNotifierProvider<UsersController, List<ManagedUser>>(UsersController.new);

final userDetailProvider = FutureProvider.family<ManagedUser, String>((ref, userId) async {
  return ref.read(userRepositoryProvider).get(userId);
});

class UsersController extends AsyncNotifier<List<ManagedUser>> {
  @override
  Future<List<ManagedUser>> build() async {
    return ref.read(userRepositoryProvider).list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(userRepositoryProvider).list());
  }
}

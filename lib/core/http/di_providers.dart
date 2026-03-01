import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/token_storage.dart';
import 'api_client.dart';
import 'providers.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final tokenProviderProvider = Provider<TokenProvider>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return _TokenProviderImpl(storage);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  return ApiClient.create(tokenProvider: tokenProvider);
});

class _TokenProviderImpl implements TokenProvider {
  final TokenStorage _storage;
  _TokenProviderImpl(this._storage);

  @override
  Future<String?> getToken() => _storage.read();
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/di_providers.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class AuthSession {
  final bool isAuthenticated;
  final String? token;
  final UserType? userType;

  const AuthSession({required this.isAuthenticated, this.token, this.userType});

  bool get isAdmin => userType == UserType.admin;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  final _stream = StreamController<void>.broadcast();
  Stream<void> get stream => _stream.stream;

  @override
  Future<AuthSession> build() async {
    final repo = ref.read(authRepositoryProvider);
    final token = await repo.getToken();
    return AuthSession(
      isAuthenticated: token != null && token.isNotEmpty,
      token: token,
      userType: _getUserTypeFromToken(token),
    );
  }

  Future<void> login({required String login, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.login(LoginRequest(login: login, password: password));
      _stream.add(null);
      return AuthSession(
        isAuthenticated: true,
        token: auth.token,
        userType: _getUserTypeFromToken(auth.token),
      );
    });
  }

  Future<void> register({
    required String nome,
    required String email,
    required String password,
    required UserType type,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.register(
        RegisterRequest(nome: nome, email: email, password: password, type: userTypeToString(type)),
      );
      _stream.add(null);
      return AuthSession(
        isAuthenticated: true,
        token: auth.token,
        userType: _getUserTypeFromToken(auth.token),
      );
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(AuthSession(isAuthenticated: false));
    _stream.add(null);
  }
}

UserType? _getUserTypeFromToken(String? token) {
  if (token == null || token.isEmpty) return null;

  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload);
    if (claims is! Map<String, dynamic>) return null;

    final type = claims['type'];
    if (type is String && type.trim().isNotEmpty) {
      return userTypeFromString(type);
    }

    final role = claims['role'];
    if (role is String && role.trim().isNotEmpty) {
      return userTypeFromString(role);
    }

    final roles = claims['roles'];
    if (roles is List) {
      for (final item in roles) {
        if (item is String && item.trim().isNotEmpty) {
          return userTypeFromString(item);
        }
      }
    }

    final authorities = claims['authorities'];
    if (authorities is List) {
      for (final item in authorities) {
        if (item is String && item.trim().isNotEmpty) {
          return userTypeFromString(item.replaceFirst('ROLE_', ''));
        }
      }
    }
  } catch (_) {
    return null;
  }

  return null;
}

String getFriendlyError(Object e) {
  if (e is AppException) return e.message;
  return 'Erro inesperado.';
}

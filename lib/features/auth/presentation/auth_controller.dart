import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/http/di_providers.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class AuthSession {
  final bool isAuthenticated;
  final String? token;
  final UserType? userType;
  final String? userId;
  final String? userEmail;
  final String? userLogin;

  const AuthSession({
    required this.isAuthenticated,
    this.token,
    this.userType,
    this.userId,
    this.userEmail,
    this.userLogin,
  });

  bool get isAdmin => userType == UserType.admin;
  bool get isParent => isAuthenticated && userType == UserType.parent;

  String? get responsibleLookupLogin {
    final login = userLogin?.trim();
    if (login != null && login.isNotEmpty) {
      if (_looksLikeEmail(login) || _looksLikePhone(login)) {
        return login;
      }
    }

    final email = userEmail?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    if (login != null && login.isNotEmpty) {
      return login;
    }

    return null;
  }
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
    if (token == null || token.isEmpty) {
      return const AuthSession(isAuthenticated: false);
    }

    return _buildAuthenticatedSession(token: token);
  }

  Future<void> login({required String login, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final auth = await repo.login(LoginRequest(login: login, password: password));
      _stream.add(null);
      return _buildAuthenticatedSession(token: auth.token, authResponse: auth, fallbackLogin: login);
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
        RegisterRequest(nome: nome, email: email, password: password, type: userTypeToApiString(type)),
      );
      _stream.add(null);
      return _buildAuthenticatedSession(token: auth.token, authResponse: auth);
    });
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(AuthSession(isAuthenticated: false));
    _stream.add(null);
  }

  Future<AuthSession> _buildAuthenticatedSession({
    required String token,
    AuthResponse? authResponse,
    String? fallbackLogin,
  }) async {
    final tokenContext = _tokenContextFromToken(token);
    final mergedLogin = authResponse?.userLogin ?? tokenContext.userLogin ?? fallbackLogin;

    UserType? userType = authResponse?.userType ?? tokenContext.userType;
    userType ??= await _resolveUserTypeByCapabilities();

    return AuthSession(
      isAuthenticated: token.isNotEmpty,
      token: token,
      userType: userType,
      userId: authResponse?.userId ?? tokenContext.userId,
      userEmail: (authResponse?.userEmail ?? tokenContext.userEmail)?.toLowerCase(),
      userLogin: mergedLogin?.trim().isEmpty == true ? null : mergedLogin?.trim(),
    );
  }

  Future<UserType> _resolveUserTypeByCapabilities() async {
    final adminStatus = await _probeStatus('/api/v1/users');
    if (adminStatus == 200) {
      return UserType.admin;
    }

    final classroomsStatus = await _probeStatus('/api/v1/classrooms');
    if (classroomsStatus == 200) {
      return UserType.teacher;
    }

    // Fallback seguro para evitar exposicao indevida de dados sensiveis.
    return UserType.parent;
  }

  Future<int?> _probeStatus(String path) async {
    try {
      await ref.read(apiClientProvider).dio.get(path);
      return 200;
    } on DioException catch (e) {
      return e.response?.statusCode;
    } catch (_) {
      return null;
    }
  }
}

class _TokenContext {
  final UserType? userType;
  final String? userId;
  final String? userEmail;
  final String? userLogin;

  const _TokenContext({
    required this.userType,
    required this.userId,
    required this.userEmail,
    required this.userLogin,
  });
}

_TokenContext _tokenContextFromToken(String? token) {
  final claims = _decodeClaims(token);
  final userLogin = _readStringClaim(
    claims,
    const ['login', 'username', 'userName', 'user_name', 'preferred_username', 'phone_number', 'phoneNumber', 'telefone', 'contact', 'celular', 'sub'],
  );

  return _TokenContext(
    userType: _getUserTypeFromClaims(claims),
    userId: _readUserId(claims),
    userEmail: _readUserEmail(claims, fallbackLogin: userLogin),
    userLogin: userLogin,
  );
}

Map<String, dynamic>? _decodeClaims(String? token) {
  if (token == null || token.isEmpty) return null;

  try {
    final parts = token.split('.');
    if (parts.length < 2) return null;

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(payload);
    if (claims is! Map<String, dynamic>) return null;
    return claims;
  } catch (_) {
    return null;
  }
}

UserType? _getUserTypeFromClaims(Map<String, dynamic>? claims) {
  if (claims == null) return null;

  for (final key in const ['type', 'userType', 'user_type', 'perfil', 'profile', 'role']) {
    final value = claims[key];
    for (final candidate in _extractRoleCandidates(value)) {
      final parsed = _tryParseUserType(candidate);
      if (parsed != null) return parsed;
    }
  }

  for (final key in const ['roles', 'authorities', 'scope', 'scp', 'groups', 'realm_access', 'resource_access']) {
    final value = claims[key];
    for (final candidate in _extractRoleCandidates(value)) {
      final parsed = _tryParseUserType(candidate);
      if (parsed != null) return parsed;
    }
  }

  return null;
}

UserType? _tryParseUserType(String raw) {
  return tryUserTypeFromString(raw);
}

Iterable<String> _extractRoleCandidates(dynamic value) sync* {
  if (value == null) return;

  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    for (final token in trimmed.split(RegExp(r'[\s,;]+'))) {
      final candidate = token.trim();
      if (candidate.isNotEmpty) {
        yield candidate;
      }
    }
    return;
  }

  if (value is List) {
    for (final item in value) {
      yield* _extractRoleCandidates(item);
    }
    return;
  }

  if (value is Map) {
    for (final key in const ['role', 'roles', 'authority', 'authorities', 'name', 'type', 'profile', 'perfil']) {
      if (value.containsKey(key)) {
        yield* _extractRoleCandidates(value[key]);
      }
    }

    for (final entry in value.entries) {
      final nested = entry.value;
      if (nested is Map || nested is List) {
        yield* _extractRoleCandidates(nested);
        continue;
      }

      final key = entry.key.toString().toLowerCase();
      final looksLikeRoleKey = key.contains('role') || key.contains('authorit') || key.contains('scope') || key.contains('group');
      if (looksLikeRoleKey && nested is String) {
        yield* _extractRoleCandidates(nested);
      }
    }
    return;
  }
}

String? _readUserId(Map<String, dynamic>? claims) {
  final explicitId = _readStringClaim(claims, const ['userId', 'user_id', 'id', 'uid']);
  if (explicitId != null) return explicitId;

  final sub = _readStringClaim(claims, const ['sub']);
  if (sub == null) return null;
  if (_looksLikeEmail(sub) || _looksLikePhone(sub)) return null;
  return sub;
}

String? _readUserEmail(Map<String, dynamic>? claims, {String? fallbackLogin}) {
  final explicitEmail = _readStringClaim(claims, const ['email', 'mail', 'userEmail', 'user_email']);
  if (explicitEmail != null) return explicitEmail.toLowerCase();

  if (fallbackLogin != null && _looksLikeEmail(fallbackLogin)) {
    return fallbackLogin.toLowerCase();
  }

  final sub = _readStringClaim(claims, const ['sub']);
  if (sub != null && _looksLikeEmail(sub)) {
    return sub.toLowerCase();
  }

  return null;
}

String? _readStringClaim(Map<String, dynamic>? claims, List<String> keys) {
  if (claims == null) return null;
  for (final key in keys) {
    final value = claims[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool _looksLikeEmail(String value) => value.contains('@');

bool _looksLikePhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 8 && digits.length <= 15;
}

String getFriendlyError(Object e) {
  if (e is AppException) return e.message;
  return 'Erro inesperado.';
}

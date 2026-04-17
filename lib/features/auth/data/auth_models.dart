class AuthResponse {
  final String token;
  final int expiresInMs;
  final UserType? userType;
  final String? userId;
  final String? userEmail;
  final String? userLogin;

  AuthResponse({
    required this.token,
    required this.expiresInMs,
    this.userType,
    this.userId,
    this.userEmail,
    this.userLogin,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final nestedUser = _firstMap(json, const ['user', 'usuario', 'account']);

    return AuthResponse(
      token: json['token']?.toString() ?? '',
      expiresInMs: _asInt(json['expiresInMs']),
      userType: _resolveUserTypeFromPayload(json, nestedUser),
      userId: _firstString(json, const ['userId', 'user_id', 'id']) ??
          (nestedUser == null ? null : _firstString(nestedUser, const ['userId', 'user_id', 'id'])),
      userEmail: _firstString(json, const ['email', 'mail', 'userEmail', 'user_email']) ??
          (nestedUser == null
              ? null
              : _firstString(nestedUser, const ['email', 'mail', 'userEmail', 'user_email'])),
      userLogin: _firstString(
            json,
            const ['login', 'username', 'userName', 'user_name', 'preferred_username', 'phone_number', 'phoneNumber'],
          ) ??
          (nestedUser == null
              ? null
              : _firstString(
                  nestedUser,
                  const ['login', 'username', 'userName', 'user_name', 'preferred_username', 'phone_number', 'phoneNumber'],
                )),
    );
  }
}

class LoginRequest {
  final String login;
  final String password;

  LoginRequest({required this.login, required this.password});

  Map<String, dynamic> toJson() => {'login': login, 'password': password};
}

class RegisterRequest {
  final String nome;
  final String email;
  final String password;
  final String type; // ADMIN | PROFESSOR | PAI etc.

  RegisterRequest({required this.nome, required this.email, required this.password, required this.type});

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'email': email,
        'password': password,
        'type': type,
      };
}

enum UserType { admin, teacher, parent }

UserType userTypeFromString(String s) {
  return tryUserTypeFromString(s) ?? UserType.parent;
}

UserType? tryUserTypeFromString(String s) {
  final normalized = _normalizeUserTypeToken(s);
  if (normalized.isEmpty) return null;

  if (normalized == 'ADMIN' || normalized.startsWith('ADMIN') || normalized.contains('_ADMIN')) {
    return UserType.admin;
  }
  if (normalized == 'TEACHER' ||
      normalized == 'PROFESSOR' ||
      normalized.startsWith('TEACHER') ||
      normalized.startsWith('PROFESSOR') ||
      normalized.startsWith('DOCENTE') ||
      normalized.contains('_TEACHER') ||
      normalized.contains('_PROFESSOR')) {
    return UserType.teacher;
  }
  if (normalized == 'PARENT' ||
      normalized == 'PAI' ||
      normalized.startsWith('PARENT') ||
      normalized.startsWith('PAI') ||
      normalized.contains('_PARENT') ||
      normalized.contains('_PAI') ||
      normalized.startsWith('RESPONS') ||
      normalized.contains('RESPONSAVEL') ||
      normalized.contains('RESPONSIBLE')) {
    return UserType.parent;
  }

  return null;
}

String userTypeToString(UserType t) {
  return userTypeToApiString(t);
}

String userTypeToApiString(UserType t) {
  return switch (t) {
    UserType.admin => 'ADMIN',
    UserType.teacher => 'PROFESSOR',
    UserType.parent => 'PAI',
  };
}

String userTypeLabel(UserType t) {
  return switch (t) {
    UserType.admin => 'Admin',
    UserType.teacher => 'Professor',
    UserType.parent => 'Responsavel',
  };
}

Map<String, dynamic>? _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
  }
  return null;
}

String? _firstString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

UserType? _resolveUserTypeFromPayload(Map<String, dynamic> root, Map<String, dynamic>? nestedUser) {
  final sources = <Map<String, dynamic>>[root];
  if (nestedUser != null) {
    sources.add(nestedUser);
  }

  for (final source in sources) {
    for (final key in const ['type', 'userType', 'user_type', 'role', 'perfil', 'profile', 'roles', 'authorities', 'groups', 'scope', 'scp']) {
      final value = source[key];
      for (final candidate in _extractTypeCandidates(value)) {
        final parsed = tryUserTypeFromString(candidate);
        if (parsed != null) {
          return parsed;
        }
      }
    }
  }

  return null;
}

Iterable<String> _extractTypeCandidates(dynamic value) sync* {
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
      yield* _extractTypeCandidates(item);
    }
    return;
  }

  if (value is Map) {
    for (final key in const ['role', 'roles', 'authority', 'authorities', 'name', 'type', 'profile', 'perfil']) {
      if (value.containsKey(key)) {
        yield* _extractTypeCandidates(value[key]);
      }
    }
  }
}

String _normalizeUserTypeToken(String raw) {
  var normalized = raw.trim().toUpperCase();
  if (normalized.startsWith('ROLE_')) {
    normalized = normalized.substring(5);
  }

  // Mantem somente caracteres ASCII relevantes para comparacao de perfil.
  return normalized.replaceAll(RegExp(r'[^A-Z0-9_]'), '');
}

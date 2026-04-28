class AuthResponse {
  final String token;
  final int expiresInMs;
  final UserType? userType;
  final String? userId;
  final String? userEmail;
  final String? userLogin;
  final String? schoolId;
  final String? schoolSlug;

  AuthResponse({
    required this.token,
    required this.expiresInMs,
    this.userType,
    this.userId,
    this.userEmail,
    this.userLogin,
    this.schoolId,
    this.schoolSlug,
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
      schoolId: _firstString(json, const ['schoolId', 'school_id', 'tenantId', 'tenant_id']),
      schoolSlug: _firstString(json, const ['schoolSlug', 'school_slug', 'tenantSlug', 'tenant_slug']),
    );
  }
}

class LoginRequest {
  final String login;
  final String password;
  final String? schoolSlug;

  LoginRequest({required this.login, required this.password, this.schoolSlug});

  Map<String, dynamic> toJson() {
    final data = {'login': login, 'password': password};
    final normalizedSchoolSlug = schoolSlug?.trim();
    if (normalizedSchoolSlug != null && normalizedSchoolSlug.isNotEmpty) {
      data['schoolSlug'] = normalizedSchoolSlug;
    }
    return data;
  }
}

class LoginSchoolOption {
  final String name;
  final String slug;

  const LoginSchoolOption({required this.name, required this.slug});

  factory LoginSchoolOption.fromJson(Map<String, dynamic> json) {
    return LoginSchoolOption(
      name: _firstString(json, const ['name', 'nome']) ?? 'Escola sem nome',
      slug: _firstString(json, const ['slug', 'schoolSlug', 'school_slug']) ?? '',
    );
  }
}

enum UserType { superAdmin, admin, teacher, parent }

UserType userTypeFromString(String s) {
  return tryUserTypeFromString(s) ?? UserType.parent;
}

UserType? tryUserTypeFromString(String s) {
  final normalized = _normalizeUserTypeToken(s);
  if (normalized.isEmpty) return null;

  if (normalized == 'SUPER_ADMIN' ||
      normalized == 'SUPERADMIN' ||
      normalized.startsWith('SUPER_ADMIN') ||
      normalized.startsWith('SUPERADMIN')) {
    return UserType.superAdmin;
  }
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
    UserType.superAdmin => 'SUPER_ADMIN',
    UserType.admin => 'ADMIN',
    UserType.teacher => 'PROFESSOR',
    UserType.parent => 'PAI',
  };
}

String userTypeLabel(UserType t) {
  return switch (t) {
    UserType.superAdmin => 'Super Admin',
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

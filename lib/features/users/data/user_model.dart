import '../../auth/data/auth_models.dart';

class ManagedUser {
  final String id;
  final String name;
  final String email;
  final UserType type;
  final bool active;

  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.active,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    return ManagedUser(
      id: _readString(json, const ['id']) ?? '',
      name: _readString(json, const ['name', 'nome']) ?? 'Usuario sem nome',
      email: _readString(json, const ['email', 'mail']) ?? '',
      type: tryUserTypeFromString(
            _readString(json, const ['type', 'userType', 'role', 'perfil']) ?? '',
          ) ??
          UserType.parent,
      active: _readBool(json, const ['active', 'enabled', 'isActive'], fallback: true),
    );
  }

  String get displayEmail => email.trim().isEmpty ? 'Sem e-mail informado' : email;

  String get roleLabel => userTypeLabel(type);

  bool matchesQuery(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return true;

    return name.toLowerCase().contains(cleanQuery) ||
        email.toLowerCase().contains(cleanQuery) ||
        roleLabel.toLowerCase().contains(cleanQuery);
  }
}

class ManagedUserCreateRequest {
  final String name;
  final String email;
  final String password;
  final UserType type;

  const ManagedUserCreateRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'type': userTypeToApiString(type),
      };
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool _readBool(Map<String, dynamic> json, List<String> keys, {required bool fallback}) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
  }
  return fallback;
}

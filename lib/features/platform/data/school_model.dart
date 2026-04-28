class ManagedSchool {
  final String id;
  final String name;
  final String slug;
  final bool active;

  const ManagedSchool({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
  });

  factory ManagedSchool.fromJson(Map<String, dynamic> json) {
    return ManagedSchool(
      id: _readString(json, const ['id']) ?? '',
      name: _readString(json, const ['name', 'nome']) ?? 'Escola sem nome',
      slug: _readString(json, const ['slug', 'schoolSlug', 'school_slug']) ?? '',
      active: _readBool(json, const ['active', 'enabled', 'isActive'], fallback: true),
    );
  }
}

class PlatformSchoolCreateRequest {
  final String schoolName;
  final String schoolSlug;
  final String adminName;
  final String adminEmail;
  final String adminPassword;

  const PlatformSchoolCreateRequest({
    required this.schoolName,
    required this.schoolSlug,
    required this.adminName,
    required this.adminEmail,
    required this.adminPassword,
  });

  Map<String, dynamic> toJson() => {
        'schoolName': schoolName,
        'schoolSlug': schoolSlug,
        'admin': {
          'name': adminName,
          'email': adminEmail,
          'password': adminPassword,
        },
      };
}

class SchoolAdminCreateRequest {
  final String name;
  final String email;
  final String password;

  const SchoolAdminCreateRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
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

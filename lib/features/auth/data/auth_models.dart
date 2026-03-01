class AuthResponse {
  final String token;
  final int expiresInMs;

  AuthResponse({required this.token, required this.expiresInMs});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: (json['token'] ?? '') as String,
      expiresInMs: (json['expiresInMs'] ?? 0) as int,
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String nome;
  final String email;
  final String password;
  final String type; // ADMIN | TEACHER | PARENT etc.

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
  switch (s.toUpperCase()) {
    case 'ADMIN':
      return UserType.admin;
    case 'TEACHER':
      return UserType.teacher;
    case 'PARENT':
      return UserType.parent;
    default:
      return UserType.parent;
  }
}

String userTypeToString(UserType t) {
  return switch (t) {
    UserType.admin => 'ADMIN',
    UserType.teacher => 'TEACHER',
    UserType.parent => 'PARENT',
  };
}

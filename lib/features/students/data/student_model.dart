import 'package:intl/intl.dart';

class Student {
  final String id;
  final String name;
  final String lastName;
  final DateTime? birthDate;
  final String classroomId;
  final String? parentUserId;
  final String? parentEmail;

  Student({
    required this.id,
    required this.name,
    required this.lastName,
    required this.birthDate,
    required this.classroomId,
    required this.parentUserId,
    required this.parentEmail,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    DateTime? bd;
    final raw = json['birthDate'];
    if (raw is String) {
      bd = DateTime.tryParse(raw);
    }

    return Student(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      birthDate: bd,
      classroomId: (json['classroomId'] ?? '') as String,
      parentUserId: json['parentUserId'] as String?,
      parentEmail: json['parentEmail'] as String?,
    );
  }

  String get fullName => '$name $lastName'.trim();
  String get birthDateLabel {
    if (birthDate == null) return '-';
    return DateFormat('dd/MM/yyyy').format(birthDate!);
  }
}

class StudentCreateRequest {
  final String name;
  final String lastName;
  final DateTime? birthDate;
  final String classroomId;

  StudentCreateRequest({required this.name, required this.lastName, required this.birthDate, required this.classroomId});

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastName': lastName,
        // backend usa java.sql.Timestamp; enviar ISO é o mais comum.
        'birthDate': birthDate?.toIso8601String(),
        'classroomId': classroomId,
      };
}

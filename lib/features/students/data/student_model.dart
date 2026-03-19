import 'package:intl/intl.dart';

class Student {
  final String id;
  final String name;
  final String lastName;
  final DateTime? birthDate;
  final String classroomId;
  final String? parentUserId;
  final String? parentName;
  final String? parentLastName;
  final String? parentContact;
  final String? parentEmail;
  final int pendingParentNoteCount;

  Student({
    required this.id,
    required this.name,
    required this.lastName,
    required this.birthDate,
    required this.classroomId,
    required this.parentUserId,
    required this.parentName,
    required this.parentLastName,
    required this.parentContact,
    required this.parentEmail,
    required this.pendingParentNoteCount,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    DateTime? bd;
    final raw = json['birthDate'];
    if (raw is String) {
      bd = DateTime.tryParse(raw);
    }

    return Student(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      birthDate: bd,
      classroomId: json['classroomId']?.toString() ?? '',
      parentUserId: json['parentUserId']?.toString(),
      parentName: _readString(
        json,
        const ['parentName', 'nomeResponsavel', 'responsibleName', 'responsible_name'],
      ),
      parentLastName: _readString(
        json,
        const ['parentLastName', 'sobrenomeResponsavel', 'responsibleLastName', 'responsible_last_name'],
      ),
      parentContact: _readString(
        json,
        const ['parentContact', 'contatoResponsavel', 'contato', 'responsibleContact', 'responsible_contact'],
      ),
      parentEmail: json['parentEmail']?.toString(),
      pendingParentNoteCount: _readInt(
        json,
        const ['pendingParentNoteCount', 'pendingParentNotesCount', 'unreadParentNoteCount'],
      ),
    );
  }

  String get fullName => '$name $lastName'.trim();

  String? get parentFullName {
    final full = [parentName, parentLastName].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    return full.trim().isEmpty ? null : full.trim();
  }

  String? get parentPrimaryContact => parentContact ?? parentEmail;

  bool get hasPendingParentNotes => pendingParentNoteCount > 0;

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
  final String parentName;
  final String parentLastName;
  final String parentContact;

  StudentCreateRequest({
    required this.name,
    required this.lastName,
    required this.birthDate,
    required this.classroomId,
    required this.parentName,
    required this.parentLastName,
    required this.parentContact,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'lastName': lastName,
        // backend usa java.sql.Timestamp; enviar ISO e o mais comum.
        'birthDate': birthDate?.toIso8601String(),
        'classroomId': classroomId,
        'parentName': parentName,
        'parentLastName': parentLastName,
        'parentContact': parentContact,
      };
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

int _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

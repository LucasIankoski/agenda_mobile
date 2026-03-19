import 'package:intl/intl.dart';

class ParentNote {
  final String id;
  final String studentId;
  final String? createdById;
  final String? createdByName;
  final String message;
  final DateTime? createdAt;
  final bool read;
  final DateTime? readAt;
  final String? readById;

  ParentNote({
    required this.id,
    required this.studentId,
    required this.createdById,
    required this.createdByName,
    required this.message,
    required this.createdAt,
    required this.read,
    required this.readAt,
    required this.readById,
  });

  factory ParentNote.fromJson(Map<String, dynamic> json) {
    return ParentNote(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      createdById: json['createdById']?.toString(),
      createdByName: json['createdByName']?.toString(),
      message: (json['message']?.toString() ?? '').trim(),
      createdAt: _parseDateTime(json['createdAt']),
      read: json['read'] == true,
      readAt: _parseDateTime(json['readAt']),
      readById: json['readById']?.toString(),
    );
  }

  String get createdAtLabel => _formatDateTime(createdAt);

  String? get readAtLabel {
    if (readAt == null) return null;
    return _formatDateTime(readAt);
  }
}

class ParentNoteCreateRequest {
  final String message;

  ParentNoteCreateRequest({required this.message});

  Map<String, dynamic> toJson() => {'message': message};
}

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
  }
  return null;
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

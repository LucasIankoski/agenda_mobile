import 'package:intl/intl.dart';

class StudentGalleryPhoto {
  final String id;
  final String studentId;
  final String? caption;
  final String imageUrl;
  final String? thumbnailUrl;
  final String? createdById;
  final String? createdByName;
  final DateTime? createdAt;
  final int? width;
  final int? height;
  final int? sizeInBytes;

  StudentGalleryPhoto({
    required this.id,
    required this.studentId,
    required this.caption,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    required this.width,
    required this.height,
    required this.sizeInBytes,
  });

  factory StudentGalleryPhoto.fromJson(Map<String, dynamic> json) {
    return StudentGalleryPhoto(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      caption: _readString(json, const ['caption', 'description', 'legend']),
      imageUrl: _readString(
            json,
            const ['imageUrl', 'url', 'fileUrl', 'downloadUrl', 'originalUrl'],
          ) ??
          '',
      thumbnailUrl: _readString(
        json,
        const ['thumbnailUrl', 'thumbUrl', 'previewUrl', 'thumbnail'],
      ),
      createdById: json['createdById']?.toString(),
      createdByName: json['createdByName']?.toString(),
      createdAt: _parseDateTime(json['createdAt']),
      width: _readIntOrNull(json, const ['width', 'imageWidth']),
      height: _readIntOrNull(json, const ['height', 'imageHeight']),
      sizeInBytes: _readIntOrNull(json, const ['sizeInBytes', 'fileSize']),
    );
  }

  String get createdAtLabel {
    if (createdAt == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(createdAt!);
  }

  String get thumbnailOrImageUrl {
    final candidate = thumbnailUrl?.trim();
    if (candidate != null && candidate.isNotEmpty) {
      return candidate;
    }
    return imageUrl;
  }

  bool get hasCaption => (caption?.trim().isNotEmpty ?? false);
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

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

int? _readIntOrNull(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

class Classroom {
  final String id;
  final String name;
  final bool active;

  Classroom({required this.id, required this.name, required this.active});

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      active: (json['active'] ?? true) as bool,
    );
  }
}

class ClassroomCreateRequest {
  final String name;
  ClassroomCreateRequest(this.name);
  Map<String, dynamic> toJson() => {'name': name};
}

class ClassroomUpdateRequest {
  final String name;
  final bool active;
  ClassroomUpdateRequest({required this.name, required this.active});
  Map<String, dynamic> toJson() => {'name': name, 'active': active};
}

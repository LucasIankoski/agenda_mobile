import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'students_controller.dart';
import '../data/student_model.dart';

final studentDetailProvider = FutureProvider.family<Student, String>((ref, id) async {
  return ref.read(studentRepositoryProvider).get(id);
});

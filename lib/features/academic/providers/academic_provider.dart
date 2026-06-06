import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/student_repository.dart';

final studentProvider = Provider<Map?>((ref) {
  return StudentRepository().getStudent();
});

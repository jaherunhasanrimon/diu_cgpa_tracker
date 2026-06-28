import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/student_repository.dart';
import '../domain/semester_tracker.dart';
import '../../auth/providers/auth_provider.dart';

final studentProvider = Provider<Map?>((ref) {
  final student = StudentRepository().getStudent();
  if (student == null) return null;

  final authState = ref.watch(authProvider);
  final studentId = authState.user?.studentId ?? '';

  return SemesterTracker.checkAndTransition(
    student: student,
    studentId: studentId,
  );
});

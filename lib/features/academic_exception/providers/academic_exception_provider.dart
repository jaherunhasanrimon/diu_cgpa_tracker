import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/academic_exception_model.dart';
import '../repository/academic_exception_repository.dart';

final academicExceptionsProvider = Provider<List<AcademicExceptionModel>>((ref) {
  return AcademicExceptionRepository().getExceptions();
});

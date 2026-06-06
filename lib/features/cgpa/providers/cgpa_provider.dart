import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic_exception/domain/exception_engine.dart';
import '../../academic_exception/providers/academic_exception_provider.dart';
import '../data/models/semester_result_model.dart';
import '../domain/cgpa_engine.dart';
import '../repository/cgpa_repository.dart';

class CgpaSummary {
  final double cgpa;
  final double completedCredits;
  final int completedSemesters;
  final int? latestSemester;
  final double? latestSgpa;

  const CgpaSummary({
    required this.cgpa,
    required this.completedCredits,
    required this.completedSemesters,
    required this.latestSemester,
    required this.latestSgpa,
  });
}

final semesterResultsProvider = Provider((ref) {
  return CgpaRepository().getResults();
});

final adjustedSemesterResultsProvider = Provider<List<SemesterResultModel>>((ref) {
  final results = ref.watch(semesterResultsProvider);
  final exceptions = ref.watch(academicExceptionsProvider);
  return ExceptionEngine().adjust(semesters: results, exceptions: exceptions);
});

final cgpaProvider = Provider<double>((ref) {
  final adjustedResults = ref.watch(adjustedSemesterResultsProvider);

  return CgpaEngine().calculate(adjustedResults);
});

final cgpaSummaryProvider = Provider<CgpaSummary>((ref) {
  final results = ref.watch(semesterResultsProvider);
  final exceptions = ref.watch(academicExceptionsProvider);

  final adjustedResults = ExceptionEngine().adjust(semesters: results, exceptions: exceptions);
  final sortedResults = [...adjustedResults]
    ..sort((first, second) => first.semester.compareTo(second.semester));

  final cgpa = CgpaEngine().calculate(sortedResults);
  final completedCredits = sortedResults.fold<double>(
    0,
    (total, result) => total + result.credit,
  );

  final sortedOriginal = [...results]
    ..sort((first, second) => first.semester.compareTo(second.semester));
  final latest = sortedOriginal.isEmpty ? null : sortedOriginal.last;

  return CgpaSummary(
    cgpa: cgpa,
    completedCredits: completedCredits,
    completedSemesters: sortedOriginal.length,
    latestSemester: latest?.semester,
    latestSgpa: latest?.sgpa,
  );
});

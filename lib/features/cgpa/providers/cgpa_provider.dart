import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic_exception/domain/exception_engine.dart';
import '../../academic_exception/providers/academic_exception_provider.dart';
import '../../auth/repository/registration_repository.dart';
import '../data/models/semester_result_model.dart';
import '../domain/cgpa_engine.dart';
import '../repository/cgpa_repository.dart';

import '../../academic/providers/academic_provider.dart';
import '../../academic/providers/curriculum_ledger_provider.dart';

class CgpaSummary {
  final double cgpa;
  final double completedCredits;
  final int completedSemesters;
  final int? latestSemester;
  final double? latestSgpa;

  // ── Irregular-student-only fields (null for regular students) ─────────────
  // These are populated from the CurriculumLedger and are NEVER used in the
  // regular student code path.

  /// Sum of credits for all non-completed courses (pending + locked + failed).
  /// Null for regular students.
  final double? incompleteCredits;

  /// Sum of credits for courses that failed and haven't been retaken yet.
  /// Null for regular students.
  final double? backlogCredits;

  /// Number of courses in the backlog (failed, not yet retaken).
  /// Null for regular students.
  final int? backlogCourseCount;

  const CgpaSummary({
    required this.cgpa,
    required this.completedCredits,
    required this.completedSemesters,
    required this.latestSemester,
    required this.latestSgpa,
    // Nullable — only set for irregular students
    this.incompleteCredits,
    this.backlogCredits,
    this.backlogCourseCount,
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

  // ── Irregular-student-only enrichment ─────────────────────────────────────
  // Regular students: isRegular == true → all three fields remain null.
  // Irregular students: read from the curriculum ledger providers.
  final student = ref.watch(studentProvider);
  final isRegular = student?['isRegular'] as bool? ?? true;

  double? incompleteCredits;
  double? backlogCredits;
  int? backlogCourseCount;

  if (!isRegular) {
    incompleteCredits = ref.watch(irregularIncompleteCreditsProvider);
    backlogCredits    = ref.watch(irregularBacklogCreditsProvider);
    backlogCourseCount = ref.watch(irregularBacklogCountProvider);
  }

  return CgpaSummary(
    cgpa: cgpa,
    completedCredits: completedCredits,
    completedSemesters: sortedOriginal.length,
    latestSemester: latest?.semester,
    latestSgpa: latest?.sgpa,
    incompleteCredits: incompleteCredits,
    backlogCredits: backlogCredits,
    backlogCourseCount: backlogCourseCount,
  );
});

/// Exposes the saved student intake (e.g. "Tri", "Spring 2024") from storage
/// so downstream widgets can map semester numbers → curriculum courses.
final studentIntakeProvider = Provider<String>((ref) {
  final profile = RegistrationRepository().get();
  return profile?.admissionTerm ?? 'Tri';
});

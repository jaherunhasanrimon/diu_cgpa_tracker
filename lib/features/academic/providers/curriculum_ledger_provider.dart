import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic_exception/providers/academic_exception_provider.dart';
import '../../cgpa/providers/cgpa_provider.dart';
import '../data/models/curriculum_course_record.dart';
import '../domain/curriculum_ledger_service.dart';
import '../providers/academic_provider.dart';

/// Builds the full per-course curriculum ledger for an **irregular** student.
///
/// Returns an empty list for regular students — their logic is entirely
/// unchanged and routes through the existing SGPA/semester system.
///
/// Reactively recomputes whenever [academicExceptionsProvider] changes,
/// allowing the dashboard to update immediately when exceptions are edited.
final curriculumLedgerProvider =
    Provider<List<CurriculumCourseRecord>>((ref) {
  final student = ref.watch(studentProvider);
  final isRegular = student?['isRegular'] as bool? ?? true;

  // ── Guard: regular students never use the ledger ───────────────────────────
  if (isRegular) return const [];

  final intake = ref.watch(studentIntakeProvider);
  final completedSemesters = (student?['semester'] as num?)?.toInt() ?? 0;
  final exceptions = ref.watch(academicExceptionsProvider);

  return CurriculumLedgerService().buildLedger(
    intake: intake,
    completedSemesters: completedSemesters,
    exceptions: exceptions,
  );
});

// ── Derived credit metric providers (irregular students only) ─────────────────
// These all return 0.0 / 0 for regular students because the ledger is empty.

/// Credits from all [CourseStatus.completed] courses.
final irregularCompletedCreditsProvider = Provider<double>((ref) {
  final ledger = ref.watch(curriculumLedgerProvider);
  return CurriculumLedgerService().completedCredits(ledger);
});

/// Credits from all non-completed courses (pending + locked + failed).
final irregularIncompleteCreditsProvider = Provider<double>((ref) {
  final ledger = ref.watch(curriculumLedgerProvider);
  return CurriculumLedgerService().incompleteCredits(ledger);
});

/// Credits from [CourseStatus.failed] courses only (backlog).
final irregularBacklogCreditsProvider = Provider<double>((ref) {
  final ledger = ref.watch(curriculumLedgerProvider);
  return CurriculumLedgerService().backlogCredits(ledger);
});

/// Number of courses in backlog (failed, not yet retaken).
final irregularBacklogCountProvider = Provider<int>((ref) {
  final ledger = ref.watch(curriculumLedgerProvider);
  return CurriculumLedgerService().backlogCourseCount(ledger);
});

/// Total program credits from the ledger (all courses combined).
final irregularTotalProgramCreditsProvider = Provider<double>((ref) {
  final ledger = ref.watch(curriculumLedgerProvider);
  return CurriculumLedgerService().totalProgramCredits(ledger);
});

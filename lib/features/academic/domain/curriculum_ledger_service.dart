import '../data/models/curriculum_course_record.dart';
import '../data/sources/cse_curriculum_source.dart';
import '../../academic_exception/data/models/academic_exception_model.dart';

/// Pure domain service that builds and queries the full per-course curriculum
/// snapshot for an **irregular** student.
///
/// Regular student code paths are completely unaffected by this class.
/// It is only instantiated when [isRegular == false].
///
/// ## How the Ledger Is Built
///
/// 1. Seed every course in the full curriculum as [CourseStatus.pending].
/// 2. Mark all courses in semesters 1..completedSemesters as [CourseStatus.completed].
/// 3. Apply exceptions (failed/dropped courses):
///    - If `completed == false`  → override to [CourseStatus.failed].
///    - If `completed == true`   → ensure it stays [CourseStatus.completed]
///      (it may have been in a future semester originally).
/// 4. Run a forward DAG cascade: for every [CourseStatus.failed] course,
///    BFS all transitively dependent courses that are NOT already [CourseStatus.completed]
///    or [CourseStatus.waived] and mark them [CourseStatus.locked].
class CurriculumLedgerService {
  /// Builds the full curriculum ledger for an irregular student.
  ///
  /// Returns a flat list of [CurriculumCourseRecord] — one entry per
  /// curriculum course, with status reflecting the student's real state.
  List<CurriculumCourseRecord> buildLedger({
    required String intake,
    required int completedSemesters,
    required List<AcademicExceptionModel> exceptions,
  }) {
    final allSemesters = CseCurriculumSource.getSemesters(intake: intake);
    final totalSemesters = allSemesters.length;

    // ── 1. Seed every course as pending ─────────────────────────────────────
    // We use a mutable map (courseCode → record) for fast O(1) updates.
    final Map<String, CurriculumCourseRecord> ledger = {};

    for (int semIndex = 0; semIndex < totalSemesters; semIndex++) {
      final semNumber = semIndex + 1;
      final courses = CseCurriculumSource.getCoursesForSemester(
        intake: intake,
        semesterNumber: semNumber,
      );
      for (final course in courses) {
        ledger[course.code] = CurriculumCourseRecord(
          courseCode: course.code,
          courseTitle: course.title,
          creditHours: course.credit,
          curriculumSemester: semNumber,
          prerequisites: course.prerequisites,
          status: CourseStatus.pending,
          attemptCount: 0,
        );
      }
    }

    // ── 2. Mark completed semesters ─────────────────────────────────────────
    // All courses from semesters 1..completedSemesters are assumed completed
    // by default (same assumption the regular-student system makes).
    for (int sem = 1; sem <= completedSemesters; sem++) {
      final courses = CseCurriculumSource.getCoursesForSemester(
        intake: intake,
        semesterNumber: sem,
      );
      for (final course in courses) {
        final existing = ledger[course.code];
        if (existing != null) {
          ledger[course.code] = existing.copyWith(
            status: CourseStatus.completed,
            attemptCount: 1,
          );
        }
      }
    }

    // ── 3. Apply exceptions ──────────────────────────────────────────────────
    // Exception records override the default "semester completed" assumption.
    for (final ex in exceptions) {
      final existing = ledger[ex.courseId];
      if (existing == null) continue; // safety guard for unknown course codes

      if (!ex.completed) {
        // Student failed / dropped this course and hasn't re-passed it yet.
        ledger[ex.courseId] = existing.copyWith(
          status: CourseStatus.failed,
          attemptCount: (existing.attemptCount).clamp(1, 999),
        );
      } else {
        // Student retook and passed — ensure it's marked completed.
        ledger[ex.courseId] = existing.copyWith(
          status: CourseStatus.completed,
          attemptCount: (existing.attemptCount + 1).clamp(1, 999),
        );
      }
    }

    // ── 4. Forward DAG cascade — lock dependents of failed courses ───────────
    // Build a reverse-adjacency map: courseCode → courses that require it.
    final Map<String, List<String>> dependents = {};
    for (final record in ledger.values) {
      for (final prereq in record.prerequisites) {
        dependents.putIfAbsent(prereq, () => []).add(record.courseCode);
      }
    }

    // BFS from every failed course to lock all reachable (non-completed) nodes.
    final failedCodes = ledger.values
        .where((r) => r.status == CourseStatus.failed)
        .map((r) => r.courseCode)
        .toList();

    for (final failedCode in failedCodes) {
      _cascadeLock(
        startCode: failedCode,
        dependents: dependents,
        ledger: ledger,
      );
    }

    return ledger.values.toList();
  }

  // ── Credit metric helpers ────────────────────────────────────────────────

  /// Sum of credits for all [CourseStatus.completed] and [CourseStatus.waived] courses.
  double completedCredits(List<CurriculumCourseRecord> ledger) {
    return ledger
        .where((r) => r.status == CourseStatus.completed || r.status == CourseStatus.waived)
        .fold(0.0, (sum, r) => sum + r.creditHours);
  }

  /// Sum of credits for all non-completed courses:
  /// [pending] + [locked] + [failed] + [inProgress].
  double incompleteCredits(List<CurriculumCourseRecord> ledger) {
    return ledger
        .where((r) => r.status != CourseStatus.completed && r.status != CourseStatus.waived)
        .fold(0.0, (sum, r) => sum + r.creditHours);
  }

  /// Sum of credits for courses that failed and haven't been retaken yet.
  double backlogCredits(List<CurriculumCourseRecord> ledger) {
    return ledger
        .where((r) => r.status == CourseStatus.failed)
        .fold(0.0, (sum, r) => sum + r.creditHours);
  }

  /// Number of courses in backlog (status == [CourseStatus.failed]).
  int backlogCourseCount(List<CurriculumCourseRecord> ledger) {
    return ledger.where((r) => r.status == CourseStatus.failed).length;
  }

  /// Total program credits (sum of all course credits in the ledger).
  double totalProgramCredits(List<CurriculumCourseRecord> ledger) {
    return ledger.fold(0.0, (sum, r) => sum + r.creditHours);
  }

  // ── Private: Forward DAG cascade lock ─────────────────────────────────────

  /// BFS forward from [startCode], marking every reachable non-completed
  /// course as [CourseStatus.locked].
  ///
  /// We skip courses that are already [CourseStatus.completed] or [CourseStatus.waived]
  /// because a student can still hold a passed/waived course even if they later failed
  /// a sibling prerequisite in a different chain.
  void _cascadeLock({
    required String startCode,
    required Map<String, List<String>> dependents,
    required Map<String, CurriculumCourseRecord> ledger,
  }) {
    final queue = <String>[startCode];
    final visited = <String>{};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      visited.add(current);

      final children = dependents[current] ?? [];
      for (final childCode in children) {
        final child = ledger[childCode];
        if (child == null) continue;

        // A completed or waived course is never locked — it was already earned.
        if (child.status == CourseStatus.completed || child.status == CourseStatus.waived) continue;

        // Only lock if not already failed (failed is a stronger signal).
        if (child.status != CourseStatus.failed) {
          ledger[childCode] = child.copyWith(status: CourseStatus.locked);
        }

        queue.add(childCode);
      }
    }
  }
}

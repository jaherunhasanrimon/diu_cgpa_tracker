import 'package:diu_cgpa_tracker/features/academic/data/models/curriculum_course_record.dart';
import 'package:diu_cgpa_tracker/features/academic/domain/curriculum_ledger_service.dart';
import 'package:diu_cgpa_tracker/features/academic_exception/data/models/academic_exception_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = CurriculumLedgerService();

  // Helper to find a record by course code
  CurriculumCourseRecord? find(List<CurriculumCourseRecord> ledger, String code) {
    try {
      return ledger.firstWhere((r) => r.courseCode == code);
    } catch (_) {
      return null;
    }
  }

  group('CurriculumLedgerService — buildLedger()', () {
    test('seeds every curriculum course as a record (no missing courses)', () {
      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 0,
        exceptions: [],
      );

      // Tri has 12 semesters worth of courses — at least a few dozen records
      expect(ledger.isNotEmpty, isTrue);

      // All semester-1 Tri courses must be present
      final sem1Codes = ['ENG101', 'MAT101', 'CSE112', 'CSE115'];
      for (final code in sem1Codes) {
        expect(find(ledger, code), isNotNull,
            reason: '$code should be in the ledger');
      }
    });

    test('fresh student (0 completed semesters) → all courses pending or locked', () {
      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 0,
        exceptions: [],
      );

      for (final record in ledger) {
        expect(
          record.status == CourseStatus.pending ||
              record.status == CourseStatus.locked,
          isTrue,
          reason: '${record.courseCode} should be pending or locked, '
              'got ${record.status}',
        );
      }
    });

    test('completed semesters → courses marked as completed', () {
      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 2,
        exceptions: [],
      );

      // Semester 1 and 2 courses should be completed
      final sem1Codes = ['ENG101', 'MAT101', 'CSE112', 'CSE115'];
      for (final code in sem1Codes) {
        expect(find(ledger, code)?.status, CourseStatus.completed,
            reason: '$code (semester 1) should be completed');
      }

      // Semester 3 courses should be pending (no exceptions)
      // PHY102 requires PHY101 which is now completed → pending
      expect(find(ledger, 'PHY102')?.status, isNot(CourseStatus.completed));
    });

    test('failed course → status is failed, not completed', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'MAT101',
          courseName: 'Mathematics - I',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 2,
        exceptions: exceptions,
      );

      expect(find(ledger, 'MAT101')?.status, CourseStatus.failed,
          reason: 'MAT101 should be failed');
    });

    test('failed course cascade-locks its dependents', () {
      // PHY101 is a prerequisite for PHY102, PHY103, CSE121, CSE122
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'PHY101',
          courseName: 'Physics-I',
          credit: 3.0,
          originalSemester: 2, // Tri semester 2 has PHY101
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 2,
        exceptions: exceptions,
      );

      // PHY101 itself → failed
      expect(find(ledger, 'PHY101')?.status, CourseStatus.failed);

      // Direct dependents of PHY101 should be locked
      expect(find(ledger, 'PHY102')?.status, CourseStatus.locked,
          reason: 'PHY102 depends on PHY101 → should be locked');
      expect(find(ledger, 'PHY103')?.status, CourseStatus.locked,
          reason: 'PHY103 depends on PHY101 → should be locked');
      expect(find(ledger, 'CSE121')?.status, CourseStatus.locked,
          reason: 'CSE121 depends on PHY101 → should be locked');
      expect(find(ledger, 'CSE122')?.status, CourseStatus.locked,
          reason: 'CSE122 depends on PHY101 → should be locked');
    });

    test('cascade lock does NOT affect courses with independent prerequisites', () {
      // CSE113 is a prerequisite for CSE123 (Data Structure) — independent of PHY101
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'PHY101',
          courseName: 'Physics-I',
          credit: 3.0,
          originalSemester: 2,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 3,
        exceptions: exceptions,
      );

      // CSE123 prerequisites: [CSE113] — CSE113 is completed (sem 2, not failed)
      // So CSE123 should NOT be locked by PHY101's failure
      final cse123 = find(ledger, 'CSE123');
      expect(cse123?.status, isNot(CourseStatus.locked),
          reason: 'CSE123 has independent prereq CSE113; '
              'PHY101 failure should not lock it');
    });

    test('completed exception → course marked completed even if in future semester', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'CSE115',
          courseName: 'Intro Bio/Chem',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: true,
          completedSemester: 3,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 2,
        exceptions: exceptions,
      );

      // Even though the course was originally in semester 1 and student completed
      // it in semester 3 (which is > completedSemesters=2), the exception's
      // completed:true should mark it as completed.
      expect(find(ledger, 'CSE115')?.status, CourseStatus.completed,
          reason: 'CSE115 was retaken and completed per exception record');
    });

    test('completed course is never cascade-locked even if sibling prerequisite fails', () {
      // ENG101 is in sem1 (completed). ENG102 requires ENG101.
      // If ENG101 is marked completed via exception, it should stay completed,
      // not get locked by some other chain.
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'MAT101',
          courseName: 'Mathematics - I',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 2,
        exceptions: exceptions,
      );

      // ENG101 has no dependency on MAT101 — must remain completed
      expect(find(ledger, 'ENG101')?.status, CourseStatus.completed,
          reason: 'ENG101 is independent of MAT101 and must stay completed');
    });
  });

  group('CurriculumLedgerService — credit metrics', () {
    test('completedCredits sums only completed-status courses', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'CSE115',
          courseName: 'Intro Bio/Chem',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 1,
        exceptions: exceptions,
      );

      final completed = service.completedCredits(ledger);
      final all = service.totalProgramCredits(ledger);

      // Semester 1 Tri: ENG101(3) + MAT101(3) + CSE112(3) + CSE115(3) = 12cr
      // CSE115 is failed → only 9cr should be completed
      expect(completed, 9.0,
          reason: 'CSE115 is failed so only 9 of 12 semester-1 credits are completed');

      // total program credits must equal sum of all course credits
      expect(all, greaterThan(0));
    });

    test('incompleteCredits + completedCredits == totalProgramCredits', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'PHY101',
          courseName: 'Physics-I',
          credit: 3.0,
          originalSemester: 2,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 3,
        exceptions: exceptions,
      );

      final total = service.totalProgramCredits(ledger);
      final completed = service.completedCredits(ledger);
      final incomplete = service.incompleteCredits(ledger);

      expect((completed + incomplete).toStringAsFixed(1),
          total.toStringAsFixed(1),
          reason: 'completedCredits + incompleteCredits must equal total');
    });

    test('backlogCredits counts only failed-status courses', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'CSE115',
          courseName: 'Intro Bio/Chem',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
        const AcademicExceptionModel(
          courseId: 'ENG101',
          courseName: 'Basic English',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 2,
        exceptions: exceptions,
      );

      expect(service.backlogCredits(ledger), 6.0,
          reason: 'Two failed courses × 3cr each = 6cr backlog');
      expect(service.backlogCourseCount(ledger), 2,
          reason: 'Two courses in backlog');
    });

    test('no exceptions → backlog is zero', () {
      final ledger = service.buildLedger(
        intake: 'Tri',
        completedSemesters: 3,
        exceptions: [],
      );
      expect(service.backlogCredits(ledger), 0.0);
      expect(service.backlogCourseCount(ledger), 0);
    });
  });
}

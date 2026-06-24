import 'package:diu_cgpa_tracker/features/cgpa/data/models/semester_result_model.dart';
import 'package:diu_cgpa_tracker/features/academic_exception/data/models/academic_exception_model.dart';
import 'package:diu_cgpa_tracker/features/academic_exception/domain/exception_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExceptionEngine Tests', () {
    test('handles empty exceptions list correctly', () {
      final semesters = [
        const SemesterResultModel(semester: 1, sgpa: 3.5, credit: 19.5),
      ];

      final adjusted = ExceptionEngine().adjust(
        semesters: semesters,
        exceptions: [],
      );

      expect(adjusted.first.credit, 19.5);
      expect(adjusted.first.sgpa, 3.5);
    });

    test('failed/incomplete course reduces credit for original semester', () {
      final semesters = [
        const SemesterResultModel(semester: 1, sgpa: 3.0, credit: 19.5),
      ];

      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'CSE115',
          courseName: 'Biology/Chemistry',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      final adjusted = ExceptionEngine().adjust(
        semesters: semesters,
        exceptions: exceptions,
      );

      expect(adjusted.first.credit, 16.5);
      expect(adjusted.first.sgpa, 3.0);
    });

    test('completed retake adds credit to completion semester', () {
      final semesters = [
        const SemesterResultModel(semester: 1, sgpa: 3.0, credit: 19.5),
        const SemesterResultModel(semester: 2, sgpa: 3.2, credit: 15.0),
        const SemesterResultModel(semester: 3, sgpa: 3.5, credit: 15.0),
      ];

      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'CSE115',
          courseName: 'Biology/Chemistry',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: true,
          completedSemester: 3,
          overridePrerequisite: false,
        ),
      ];

      final adjusted = ExceptionEngine().adjust(
        semesters: semesters,
        exceptions: exceptions,
      );

      // Semester 1 credit reduced by 3
      expect(adjusted[0].credit, 16.5);
      // Semester 2 credit remains unchanged
      expect(adjusted[1].credit, 15.0);
      // Semester 3 credit increased by 3
      expect(adjusted[2].credit, 18.0);
    });

    test('generatePlanForSemester blocks course if prerequisite is not met', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'PHY101',
          courseName: 'Physics I',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
      ];

      // Standard Tri Curriculum L1T3 (Semester 3) — corrected prerequisites:
      // PHY102 prereq: [PHY101] → BLOCKED when PHY101 fails
      // PHY103 prereq: [PHY101] → BLOCKED when PHY101 fails
      // CSE123 prereq: [CSE113] → AVAILABLE (CSE113 is from Sem2, completed)
      // CSE121 prereq: [CSE123] → AVAILABLE (CSE123 is available)
      final plan = ExceptionEngine().generatePlanForSemester(
        intake: 'Tri',
        targetSemester: 3,
        exceptions: exceptions,
      );

      // PHY102 and PHY103 are blocked (depend on failed PHY101)
      final blockedCodes = plan.blockedCourses.map((c) => c.code).toList();
      expect(blockedCodes.contains('PHY102'), isTrue);
      expect(blockedCodes.contains('PHY103'), isTrue);

      // CSE123 is NOT blocked (its prereq CSE113 is from Sem2, already done)
      expect(blockedCodes.contains('CSE123'), isFalse);

      // PHY102 is not in regular courses
      final regularCodes = plan.regularCourses.map((c) => c.code).toList();
      expect(regularCodes.contains('PHY102'), isFalse);
    });

    test('generatePlanForSemester unlocks course if override is active', () {
      final exceptions = [
        const AcademicExceptionModel(
          courseId: 'PHY101',
          courseName: 'Physics I',
          credit: 3.0,
          originalSemester: 1,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: false,
        ),
        const AcademicExceptionModel(
          courseId: 'PHY102',
          courseName: 'Physics II',
          credit: 3.0,
          originalSemester: 3,
          type: 'FAILED',
          completed: false,
          overridePrerequisite: true, // override active → unlocks PHY102
        ),
      ];

      final plan = ExceptionEngine().generatePlanForSemester(
        intake: 'Tri',
        targetSemester: 3,
        exceptions: exceptions,
      );

      // PHY102 should be in regular (unlocked) list now due to override
      final regularCodes = plan.regularCourses.map((c) => c.code).toList();
      expect(regularCodes.contains('PHY102'), isTrue);

      // PHY103 is still blocked (no override on PHY103)
      final blockedCodes = plan.blockedCourses.map((c) => c.code).toList();
      expect(blockedCodes.contains('PHY103'), isTrue);

      // CSE123 is NOT blocked (its prereq CSE113 is completed — not affected by PHY101 failure)
      expect(blockedCodes.contains('CSE123'), isFalse);
    });
  });
}

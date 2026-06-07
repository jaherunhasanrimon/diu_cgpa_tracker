import '../../cgpa/data/models/semester_result_model.dart';
import '../../academic/data/models/course_model.dart';
import '../../academic/data/sources/cse_curriculum_source.dart';
import '../data/models/academic_exception_model.dart';
import '../data/models/student_semester_plan.dart';

class ExceptionEngine {
  List<SemesterResultModel> adjust({
    required List<SemesterResultModel> semesters,
    required List<AcademicExceptionModel> exceptions,
  }) {
    final List<SemesterResultModel> adjusted = [];

    for (final s in semesters) {
      double credit = s.credit;

      // Apply credit adjustments
      for (final e in exceptions) {
        if (e.originalSemester == s.semester) {
          // Deduct failed/incomplete credit from original semester
          credit -= e.credit;
        }
        if (e.completed && e.completedSemester == s.semester) {
          // Add back retaken credit in completion semester
          credit += e.credit;
        }
      }

      adjusted.add(
        SemesterResultModel(
          semester: s.semester,
          sgpa: s.sgpa,
          credit: credit.clamp(0.0, double.infinity),
        ),
      );
    }

    return adjusted..sort((a, b) => a.semester.compareTo(b.semester));
  }

  StudentSemesterPlan generatePlanForSemester({
    required String intake,
    required int targetSemester,
    required List<AcademicExceptionModel> exceptions,
  }) {
    // 1. Get standard courses for the target semester
    final targetCourses = CseCurriculumSource.getCoursesForSemester(
      intake: intake,
      semesterNumber: targetSemester,
    );

    // 2. Identify the set of completed courses before target semester
    final Set<String> completedCourseCodes = {};

    // Standard curriculum courses from semesters 1 to targetSemester - 1
    for (int sem = 1; sem < targetSemester; sem++) {
      final semCourses = CseCurriculumSource.getCoursesForSemester(
        intake: intake,
        semesterNumber: sem,
      );
      for (final c in semCourses) {
        completedCourseCodes.add(c.code);
      }
    }

    // Adjust completed set based on exceptions
    for (final e in exceptions) {
      if (e.originalSemester < targetSemester) {
        if (!e.completed || (e.completedSemester != null && e.completedSemester! >= targetSemester)) {
          // If not completed yet, or completed in this semester or later, it is NOT completed before targetSemester
          completedCourseCodes.remove(e.courseId);
        } else if (e.completed && e.completedSemester! < targetSemester) {
          // If completed in a prior semester, it IS completed
          completedCourseCodes.add(e.courseId);
        }
      }
    }

    // 3. Separate standard courses of targetSemester into available vs blocked
    final List<CourseModel> regularCourses = [];
    final List<CourseModel> blockedCourses = [];

    for (final course in targetCourses) {
      // Check if this course is overridden
      final isOverridden = exceptions.any((e) => e.courseId == course.code && e.overridePrerequisite);

      if (isOverridden) {
        regularCourses.add(course);
        continue;
      }

      // Check prerequisites
      bool allPrereqsMet = true;
      for (final prereq in course.prerequisites) {
        if (!completedCourseCodes.contains(prereq)) {
          allPrereqsMet = false;
          break;
        }
      }

      if (allPrereqsMet) {
        regularCourses.add(course);
      } else {
        blockedCourses.add(course);
      }
    }

    // 4. Determine pending retakes/incomplete courses to suggest for this semester
    final List<CourseModel> retakeCourses = [];
    final allIntakeCourses = CseCurriculumSource.getAllCourses(intake: intake);

    for (final e in exceptions) {
      // Only consider courses that failed in a previous semester and aren't yet completed
      if (e.originalSemester < targetSemester && !e.completed) {
        // Include this course as a retake for targetSemester only if:
        // • no planned semester is set (unscheduled → user hasn't picked a semester yet), OR
        // • the planned semester exactly matches this targetSemester
        final isScheduledForHere =
            e.completedSemester == null || e.completedSemester == targetSemester;
        if (!isScheduledForHere) continue;

        final courseDetails = allIntakeCourses.firstWhere(
          (c) => c.code == e.courseId,
          orElse: () => CourseModel(code: e.courseId, title: e.courseName, credit: e.credit),
        );
        retakeCourses.add(courseDetails);
      }
    }

    // 5. Compute total credits for this semester plan
    double totalCredits = 0.0;
    for (final c in regularCourses) {
      totalCredits += c.credit;
    }
    for (final c in retakeCourses) {
      totalCredits += c.credit;
    }

    return StudentSemesterPlan(
      semester: targetSemester,
      regularCourses: regularCourses,
      retakeCourses: retakeCourses,
      blockedCourses: blockedCourses,
      totalCredits: totalCredits,
    );
  }
}

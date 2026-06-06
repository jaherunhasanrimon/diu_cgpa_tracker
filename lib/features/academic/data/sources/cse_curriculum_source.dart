import '../models/semester_model.dart';
import '../models/course_model.dart';
import 'cse_curriculum_data.dart';

class CseCurriculumSource {
  static List<SemesterModel> getSemesters({required String intake}) {
    final intakeKey = CseCurriculumData.courses.containsKey(intake) ? intake : "Tri";
    final semestersCourses = CseCurriculumData.courses[intakeKey] ?? [];

    return List.generate(
      semestersCourses.length,
      (index) {
        final courses = semestersCourses[index];
        final totalCredit = courses.fold<double>(0.0, (sum, c) => sum + c.credit);
        return SemesterModel(
          name: 'Level ${(index ~/ 3) + 1} Term ${(index % 3) + 1}',
          semesterNumber: index + 1,
          credit: totalCredit,
        );
      },
    );
  }

  static List<String> getSupportedIntakes() {
    return CseCurriculumData.courses.keys.toList(growable: false);
  }

  static List<CourseModel> getCoursesForSemester({required String intake, required int semesterNumber}) {
    final intakeKey = CseCurriculumData.courses.containsKey(intake) ? intake : "Tri";
    final semestersCourses = CseCurriculumData.courses[intakeKey] ?? [];
    final index = semesterNumber - 1;
    if (index >= 0 && index < semestersCourses.length) {
      return semestersCourses[index];
    }
    return [];
  }

  static List<CourseModel> getAllCourses({required String intake}) {
    final intakeKey = CseCurriculumData.courses.containsKey(intake) ? intake : "Tri";
    final semestersCourses = CseCurriculumData.courses[intakeKey] ?? [];
    return semestersCourses.expand((c) => c).toList();
  }
}

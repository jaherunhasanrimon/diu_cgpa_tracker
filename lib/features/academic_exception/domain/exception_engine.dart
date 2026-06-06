import '../../cgpa/data/models/semester_result_model.dart';
import '../../cgpa/domain/grade_point_engine.dart';
import '../data/models/academic_exception_model.dart';

class ExceptionEngine {
  List<SemesterResultModel> adjust({
    required List<SemesterResultModel> semesters,
    required List<AcademicExceptionModel> exceptions,
  }) {
    // Return copy if no exceptions to process
    if (exceptions.isEmpty) {
      return List.from(semesters);
    }

    final Map<int, SemesterResultModel> adjustedMap = {
      for (final s in semesters) s.semester: s
    };

    final gradePointEngine = GradePointEngine();

    for (final exception in exceptions) {
      final semesterNum = exception.semester;
      final original = adjustedMap[semesterNum];
      if (original == null) {
        continue;
      }

      if (exception.type == 'dropped') {
        // Subtract dropped credit from semester completed credits
        final newCredit = (original.credit - exception.credit).clamp(0.0, double.infinity);
        adjustedMap[semesterNum] = SemesterResultModel(
          semester: original.semester,
          sgpa: original.sgpa,
          credit: newCredit,
        );
      } else if (exception.type == 'retake' || exception.type == 'improvement') {
        final oldGrade = exception.oldGrade;
        final newGrade = exception.newGrade;

        if (oldGrade != null && newGrade != null && newGrade.toLowerCase() != 'pending') {
          try {
            final oldGp = gradePointEngine.calculate(oldGrade);
            final newGp = gradePointEngine.calculate(newGrade);
            final gpDiff = newGp - oldGp;

            if (original.credit > 0) {
              // Formula: newSgpa = (oldSgpa * semesterCredit + gpDiff * courseCredit) / semesterCredit
              final newSgpa = (original.sgpa * original.credit + gpDiff * exception.credit) / original.credit;
              adjustedMap[semesterNum] = SemesterResultModel(
                semester: original.semester,
                sgpa: newSgpa,
                credit: original.credit,
              );
            }
          } catch (_) {
            // Skip if grade point is invalid
          }
        }
      }
    }

    return adjustedMap.values.toList()
      ..sort((a, b) => a.semester.compareTo(b.semester));
  }
}

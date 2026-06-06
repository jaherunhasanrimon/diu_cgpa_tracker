import '../data/models/semester_model.dart';
import '../data/sources/cse_curriculum_source.dart';

class CurriculumEngine {
  List<String> supportedIntakes() {
    return CseCurriculumSource.getSupportedIntakes();
  }

  double totalCreditForIntake({required String intake}) {
    return CseCurriculumSource.getSemesters(
      intake: intake,
    ).fold<double>(0, (total, semester) => total + semester.credit);
  }

  List<SemesterModel> generatePlan({
    required String intake,

    required int currentSemester,
  }) {
    final semesters = CseCurriculumSource.getSemesters(intake: intake);

    return semesters.take(currentSemester).toList();
  }
}

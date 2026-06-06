import '../data/models/semester_model.dart';
import '../data/sources/cse_curriculum_source.dart';

class CurriculumEngine {
  List<String> supportedIntakes() {
    return CseCurriculumSource.getSupportedIntakes();
  }

  List<SemesterModel> generatePlan({
    required String intake,

    required int currentSemester,
  }) {
    final semesters = CseCurriculumSource.getSemesters(intake: intake);

    return semesters.take(currentSemester).toList();
  }
}

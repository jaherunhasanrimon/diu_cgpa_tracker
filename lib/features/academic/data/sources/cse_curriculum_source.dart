import '../models/semester_model.dart';
import 'cse_curriculum_data.dart';

class CseCurriculumSource {
  static List<SemesterModel> getSemesters({required String intake}) {
    final credits = CseCurriculumData.credits[intake] ?? [];

    return List.generate(
      credits.length,
      (index) => SemesterModel(
        name: 'Level ${(index ~/ 3) + 1} Term ${(index % 3) + 1}',

        semesterNumber: index + 1,

        credit: credits[index].toDouble(),
      ),
    );
  }

  static List<String> getSupportedIntakes() {
    return CseCurriculumData.credits.keys.toList(growable: false);
  }
}

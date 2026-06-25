import '../data/models/semester_model.dart';
import '../data/sources/cse_curriculum_source.dart';

class CurriculumEngine {
  List<String> supportedIntakes() {
    return CseCurriculumSource.getSupportedIntakes();
  }

  /// Parses a DIU student ID (e.g. "241-15-12345") and returns the
  /// matching admission intake string, or `null` if unrecognised.
  ///
  /// Mapping rules (app is valid from intake 241 onwards):
  ///   241 → "Spring 2024"
  ///   242 → "Fall 2024"
  ///   251 / 252 / 253 / 261 … → "Tri"   (tri-semester system)
  static String? studentIdToIntake(String studentId) {
    final trimmed = studentId.trim();
    if (trimmed.length < 3) return null;

    // The prefix is the first 3 digits before the first '-' (or just first 3 chars).
    final prefix = trimmed.split('-').first;
    if (prefix.length < 3) return null;

    final code = int.tryParse(prefix);
    if (code == null) return null;

    // Pre-tri-semester era (only Spring 2024 and Fall 2024 are supported).
    if (code == 241) return 'Spring 2024';
    if (code == 242) return 'Fall 2024';

    // Tri-semester system starts from 251.  Any valid 3-digit code ≥ 251
    // whose first two digits form a year ≥ 25 is a tri-semester intake.
    final yearPart = code ~/ 10; // e.g. 251 → 25, 261 → 26
    final semPart  = code  % 10; // e.g. 251 → 1,  253 → 3
    if (yearPart >= 25 && semPart >= 1 && semPart <= 3) return 'Tri';

    return null; // unknown / unsupported intake
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

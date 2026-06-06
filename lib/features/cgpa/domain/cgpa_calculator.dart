import '../data/models/semester_result_model.dart';
import 'cgpa_engine.dart';

class CgpaCalculator {
  static double calculate(List<SemesterResultModel> semesters) {
    return CgpaEngine().calculate(semesters);
  }
}

import '../data/models/semester_model.dart';
import '../data/sources/cse_curriculum_source.dart';


class CurriculumEngine {


  List<SemesterModel> generatePlan({

    required String intake,

    required int currentSemester,


  }){


    return CseCurriculumSource.semesters;


  }


}
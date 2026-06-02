import '../data/models/student_profile_model.dart';

import 'curriculum_engine.dart';
import 'intake_resolver.dart';


class StudentProfileBuilder {


  final _curriculumEngine = CurriculumEngine();

  final _intakeResolver = IntakeResolver();



  StudentProfileModel build({

    required String department,

    required String intake,

    required int currentSemester,

  }) {


    final intakeData =
    _intakeResolver.resolve(intake);



    final curriculum =
    _curriculumEngine.generatePlan(

      intake: intake,

      currentSemester: currentSemester,

    );



    return StudentProfileModel(

      department: department,

      intake: intake,

      batch: intakeData.batch,

      currentSemester: currentSemester,

      semesterSystem: intakeData.system.name,

      curriculumPlan: curriculum,

    );


  }


}
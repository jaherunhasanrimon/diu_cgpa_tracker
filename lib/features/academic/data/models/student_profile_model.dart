import 'curriculum_model.dart';


class StudentProfileModel {

  final String department;

  final String intake;

  final String batch;

  final int currentSemester;

  final String semesterSystem;

  final List<SemesterModel> curriculumPlan;


  const StudentProfileModel({

    required this.department,

    required this.intake,

    required this.batch,

    required this.currentSemester,

    required this.semesterSystem,

    required this.curriculumPlan,

  });


}
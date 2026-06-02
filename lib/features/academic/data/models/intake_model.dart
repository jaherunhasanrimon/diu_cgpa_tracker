enum SemesterSystem {
  bi,
  tri,
  hybrid,
}


class IntakeModel {


  final String intake;

  final String batch;

  final SemesterSystem system;

  final int totalSemesters;



  const IntakeModel({

    required this.intake,
    required this.batch,
    required this.system,
    required this.totalSemesters,

  });


}
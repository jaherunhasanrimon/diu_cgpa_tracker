import '../data/models/intake_model.dart';


class IntakeResolver {


  IntakeModel resolve(String intake) {


    switch (intake) {


      case "Spring 2024":

        return const IntakeModel(

          intake: "Spring 2024",

          batch: "66",

          system: SemesterSystem.hybrid,

          totalSemesters: 11,

        );



      case "Fall 2024":

        return const IntakeModel(

          intake: "Fall 2024",

          batch: "68",

          system: SemesterSystem.hybrid,

          totalSemesters: 12,

        );



      default:

        return IntakeModel(

          intake: intake,

          batch: _calculateBatch(intake),

          system: SemesterSystem.tri,

          totalSemesters: 12,

        );

    }


  }




  String _calculateBatch(String intake) {


    // Temporary automatic calculation
    // improve later


    if (intake.contains("2025")) {

      return "69";

    }


    return "Future";

  }


}
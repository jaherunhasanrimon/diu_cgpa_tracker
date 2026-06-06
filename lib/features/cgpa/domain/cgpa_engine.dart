import '../data/models/semester_result_model.dart';


class CgpaEngine {


  double calculate(

      List<SemesterResultModel> semesters,

      ) {


    double totalWeightedPoint = 0;

    double totalCredit = 0;


    for (final semester in semesters) {


      totalWeightedPoint +=
          semester.sgpa * semester.credit;


      totalCredit += semester.credit;


    }


    if (totalCredit == 0) {

      return 0;

    }


    return totalWeightedPoint / totalCredit;


  }

}
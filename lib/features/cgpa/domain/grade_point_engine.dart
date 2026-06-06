class GradePointEngine {


  double calculate(String grade) {

    switch (grade.toUpperCase()) {

      case 'A+':
        return 4.00;

      case 'A':
        return 3.75;

      case 'A-':
        return 3.50;

      case 'B+':
        return 3.25;

      case 'B':
        return 3.00;

      case 'B-':
        return 2.75;

      case 'C+':
        return 2.50;

      case 'C':
        return 2.25;

      case 'D':
        return 2.00;

      case 'F':
        return 0.00;


      default:
        throw Exception(
          'Invalid Grade: $grade',
        );
    }

  }

}
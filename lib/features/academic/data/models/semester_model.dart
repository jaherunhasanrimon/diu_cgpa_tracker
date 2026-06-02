import 'course_model.dart';


class SemesterModel {


  final int semesterNumber;

  final String name;

  final List<CourseModel> courses;


  const SemesterModel({

    required this.semesterNumber,
    required this.name,
    required this.courses,

  });



  double get totalCredit {


    return courses.fold(

      0,

          (sum, course) => sum + course.credit,

    );


  }


}
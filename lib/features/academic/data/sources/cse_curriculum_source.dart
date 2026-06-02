import '../models/course_model.dart';
import '../models/semester_model.dart';


class CseCurriculumSource {


  static final List<SemesterModel> semesters = [


    SemesterModel(

      semesterNumber: 1,

      name: "L1T1",

      courses: [

        CourseModel(
          code: "ENG101",
          title: "Basic Functional English",
          credit: 3,
        ),


        CourseModel(
          code: "MAT101",
          title: "Mathematics I",
          credit: 3,
        ),


        CourseModel(
          code: "CSE112",
          title: "Computer Fundamentals",
          credit: 3,
        ),


      ],

    ),



  ];



}
import '../../../academic/data/models/course_model.dart';

class StudentSemesterPlan {
  final int semester;
  final List<CourseModel> regularCourses;
  final List<CourseModel> retakeCourses;
  final List<CourseModel> blockedCourses;
  final double totalCredits;

  const StudentSemesterPlan({
    required this.semester,
    required this.regularCourses,
    required this.retakeCourses,
    required this.blockedCourses,
    required this.totalCredits,
  });

  StudentSemesterPlan copyWith({
    int? semester,
    List<CourseModel>? regularCourses,
    List<CourseModel>? retakeCourses,
    List<CourseModel>? blockedCourses,
    double? totalCredits,
  }) {
    return StudentSemesterPlan(
      semester: semester ?? this.semester,
      regularCourses: regularCourses ?? this.regularCourses,
      retakeCourses: retakeCourses ?? this.retakeCourses,
      blockedCourses: blockedCourses ?? this.blockedCourses,
      totalCredits: totalCredits ?? this.totalCredits,
    );
  }
}

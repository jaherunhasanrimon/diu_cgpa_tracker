class CourseModel {

  final String code;
  final String title;
  final double credit;
  final List<String> prerequisites;


  const CourseModel({

    required this.code,
    required this.title,
    required this.credit,
    this.prerequisites = const [],

  });

}
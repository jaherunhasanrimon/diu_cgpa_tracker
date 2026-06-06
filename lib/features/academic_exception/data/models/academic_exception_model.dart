class AcademicExceptionModel {
  final String id;
  final String type; // 'retake', 'improvement', 'dropped'
  final String courseCode;
  final String courseTitle;
  final double credit;
  final int semester;
  final String? oldGrade;
  final String? newGrade;

  const AcademicExceptionModel({
    required this.id,
    required this.type,
    required this.courseCode,
    required this.courseTitle,
    required this.credit,
    required this.semester,
    this.oldGrade,
    this.newGrade,
  });

  AcademicExceptionModel copyWith({
    String? id,
    String? type,
    String? courseCode,
    String? courseTitle,
    double? credit,
    int? semester,
    String? oldGrade,
    String? newGrade,
  }) {
    return AcademicExceptionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      credit: credit ?? this.credit,
      semester: semester ?? this.semester,
      oldGrade: oldGrade ?? this.oldGrade,
      newGrade: newGrade ?? this.newGrade,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'credit': credit,
      'semester': semester,
      'oldGrade': oldGrade,
      'newGrade': newGrade,
    };
  }

  factory AcademicExceptionModel.fromMap(Map map) {
    return AcademicExceptionModel(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      courseCode: map['courseCode']?.toString() ?? '',
      courseTitle: map['courseTitle']?.toString() ?? '',
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      semester: (map['semester'] as num?)?.toInt() ?? 1,
      oldGrade: map['oldGrade']?.toString(),
      newGrade: map['newGrade']?.toString(),
    );
  }
}

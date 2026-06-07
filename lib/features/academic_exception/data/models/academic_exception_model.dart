class AcademicExceptionModel {
  final String courseId;
  final String courseName;
  final double credit;
  final int originalSemester;
  final String type; // 'FAILED', 'DROPPED', 'INCOMPLETE'
  final bool completed;
  final int? completedSemester;
  final bool overridePrerequisite;

  const AcademicExceptionModel({
    required this.courseId,
    required this.courseName,
    required this.credit,
    required this.originalSemester,
    required this.type,
    required this.completed,
    this.completedSemester,
    required this.overridePrerequisite,
  });

  AcademicExceptionModel copyWith({
    String? courseId,
    String? courseName,
    double? credit,
    int? originalSemester,
    String? type,
    bool? completed,
    int? completedSemester,
    /// Set to true to explicitly clear completedSemester back to null.
    bool clearCompletedSemester = false,
    bool? overridePrerequisite,
  }) {
    return AcademicExceptionModel(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      credit: credit ?? this.credit,
      originalSemester: originalSemester ?? this.originalSemester,
      type: type ?? this.type,
      completed: completed ?? this.completed,
      completedSemester: clearCompletedSemester
          ? null
          : (completedSemester ?? this.completedSemester),
      overridePrerequisite: overridePrerequisite ?? this.overridePrerequisite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'credit': credit,
      'originalSemester': originalSemester,
      'type': type,
      'completed': completed,
      'completedSemester': completedSemester,
      'overridePrerequisite': overridePrerequisite,
    };
  }

  factory AcademicExceptionModel.fromMap(Map map) {
    return AcademicExceptionModel(
      courseId: map['courseId']?.toString() ?? '',
      courseName: map['courseName']?.toString() ?? '',
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      originalSemester: (map['originalSemester'] as num?)?.toInt() ?? 1,
      type: map['type']?.toString() ?? 'FAILED',
      completed: map['completed'] as bool? ?? false,
      completedSemester: (map['completedSemester'] as num?)?.toInt(),
      overridePrerequisite: map['overridePrerequisite'] as bool? ?? false,
    );
  }
}

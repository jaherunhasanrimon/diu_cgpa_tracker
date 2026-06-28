/// The FSM status for a single course in an irregular student's curriculum ledger.
enum CourseStatus {
  /// All prerequisites are met; the student has not yet registered for this course.
  pending,

  /// One or more prerequisites are in [failed] state — student cannot register.
  locked,

  /// The student is currently enrolled in this course in the running semester.
  inProgress,

  /// The student has passed this course (any attempt).
  completed,

  /// The student attempted this course and did not pass; eligible for retake.
  failed,

  /// The course has been waived (e.g. credit transfer, waiver).
  waived,
}

/// Represents one course's tracking record in an irregular student's
/// full curriculum snapshot.
///
/// This is NOT used for regular students. Regular student logic is
/// entirely unchanged and routed through the existing SGPA/semester system.
class CurriculumCourseRecord {
  final String courseCode;
  final String courseTitle;
  final double creditHours;

  /// The semester number this course appears in under the standard curriculum
  /// template (1-indexed). Used only as a reference point — not a constraint
  /// for irregular students.
  final int curriculumSemester;

  final List<String> prerequisites;

  final CourseStatus status;

  final double? gradePoint;

  /// Number of times the student has sat this course (0 = never attempted).
  final int attemptCount;

  const CurriculumCourseRecord({
    required this.courseCode,
    required this.courseTitle,
    required this.creditHours,
    required this.curriculumSemester,
    required this.prerequisites,
    required this.status,
    this.gradePoint,
    this.attemptCount = 0,
  });

  CurriculumCourseRecord copyWith({
    CourseStatus? status,
    double? gradePoint,
    int? attemptCount,
  }) {
    return CurriculumCourseRecord(
      courseCode: courseCode,
      courseTitle: courseTitle,
      creditHours: creditHours,
      curriculumSemester: curriculumSemester,
      prerequisites: prerequisites,
      status: status ?? this.status,
      gradePoint: gradePoint ?? this.gradePoint,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  @override
  String toString() =>
      'CurriculumCourseRecord($courseCode, $status, ${creditHours}cr)';
}

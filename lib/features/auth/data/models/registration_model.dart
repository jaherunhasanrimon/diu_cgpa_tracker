import '../../../cgpa/data/models/semester_result_model.dart';
import '../../../academic_exception/data/models/academic_exception_model.dart';

class RegistrationModel {
  final String university;
  final String name;
  final String email;

  final String department;
  final String admissionTerm;
  final String year;

  final int completedSemester;

  final List<SemesterResultModel> results;

  final Map<int, double> sgpaHistory;

  final bool isRegular;
  final List<AcademicExceptionModel> exceptions;

  RegistrationModel({
    required this.university,
    required this.name,
    required this.email,

    required this.department,
    required this.admissionTerm,
    required this.year,

    required this.completedSemester,

    required this.results,

    this.sgpaHistory = const {},
    this.isRegular = true,
    this.exceptions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'university': university,
      'name': name,
      'email': email,

      'department': department,
      'admissionTerm': admissionTerm,
      'year': year,

      'completedSemester': completedSemester,

      'results': results
          .map(
            (e) => {'semester': e.semester, 'sgpa': e.sgpa, 'credit': e.credit},
          )
          .toList(),

      'sgpaHistory': sgpaHistory.map((k, v) => MapEntry(k.toString(), v)),
      'isRegular': isRegular,
      'exceptions': exceptions.map((e) => e.toMap()).toList(),
    };
  }

  factory RegistrationModel.fromMap(Map data) {
    return RegistrationModel(
      university: data['university'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',

      department: data['department'] ?? '',
      admissionTerm: data['admissionTerm'] ?? '',
      year: data['year'] ?? '',

      completedSemester: data['completedSemester'] ?? 0,

      results: (data['results'] as List?)
              ?.map(
                (e) => SemesterResultModel(
                  semester: (e['semester'] as num).toInt(),
                  sgpa: (e['sgpa'] as num).toDouble(),
                  credit: (e['credit'] as num).toDouble(),
                ),
              )
              .toList() ??
          const [],

      sgpaHistory: (() {
        final map = <int, double>{};
        final raw = data['sgpaHistory'];
        if (raw is Map) {
          raw.forEach((k, v) {
            try {
              final key = int.parse(k.toString());
              map[key] = (v as num).toDouble();
            } catch (_) {}
          });
        }
        return map;
      })(),
      isRegular: data['isRegular'] as bool? ?? true,
      exceptions: (data['exceptions'] as List?)
              ?.map((e) => AcademicExceptionModel.fromMap(e))
              .toList() ??
          const [],
    );
  }
}

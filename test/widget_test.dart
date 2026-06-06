import 'package:diu_cgpa_tracker/features/auth/providers/registration_provider.dart';
import 'package:diu_cgpa_tracker/features/cgpa/data/models/semester_result_model.dart';
import 'package:diu_cgpa_tracker/features/cgpa/domain/cgpa_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates weighted CGPA from curriculum credits', () {
    final cgpa = CgpaEngine().calculate(const [
      SemesterResultModel(semester: 1, sgpa: 3, credit: 19.5),
      SemesterResultModel(semester: 2, sgpa: 3, credit: 19.5),
      SemesterResultModel(semester: 3, sgpa: 3, credit: 13.5),
    ]);

    expect(cgpa, 3.0);
  });

  test('registration SGPA input uses curriculum credits', () {
    final notifier = RegistrationNotifier()
      ..setAcademicInfo(
        department: 'Computer Science & Engineering',
        admissionTerm: 'Spring 2024',
        completedSemester: 3,
      )
      ..setSemesterSGPA(1, 3)
      ..setSemesterSGPA(2, 3)
      ..setSemesterSGPA(3, 3);

    expect(notifier.state.results.map((result) => result.credit), [
      19.5,
      19.5,
      13.5,
    ]);
    expect(CgpaEngine().calculate(notifier.state.results), 3.0);
  });

  test('updating an existing result does not reuse stale credit', () {
    final notifier = RegistrationNotifier()
      ..setAcademicInfo(
        department: 'Computer Science & Engineering',
        admissionTerm: 'Spring 2024',
        completedSemester: 3,
      )
      ..updateResults(const [
        SemesterResultModel(semester: 1, sgpa: 2, credit: 0),
      ])
      ..updateSemesterResult(1, 3);

    expect(notifier.state.results.single.credit, 19.5);
  });
}

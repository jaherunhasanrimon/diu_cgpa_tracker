import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cgpa_engine.dart';
import '../repository/cgpa_repository.dart';

class CgpaSummary {
  final double cgpa;
  final double completedCredits;
  final int completedSemesters;
  final int? latestSemester;
  final double? latestSgpa;

  const CgpaSummary({
    required this.cgpa,
    required this.completedCredits,
    required this.completedSemesters,
    required this.latestSemester,
    required this.latestSgpa,
  });
}

final semesterResultsProvider = Provider((ref) {
  return CgpaRepository().getResults();
});

final cgpaProvider = Provider<double>((ref) {
  final results = ref.watch(semesterResultsProvider);

  return CgpaEngine().calculate(results);
});

final cgpaSummaryProvider = Provider<CgpaSummary>((ref) {
  final results = ref.watch(semesterResultsProvider);
  final sortedResults = [...results]
    ..sort((first, second) => first.semester.compareTo(second.semester));

  final cgpa = CgpaEngine().calculate(sortedResults);
  final completedCredits = sortedResults.fold<double>(
    0,
    (total, result) => total + result.credit,
  );
  final latest = sortedResults.isEmpty ? null : sortedResults.last;

  return CgpaSummary(
    cgpa: cgpa,
    completedCredits: completedCredits,
    completedSemesters: sortedResults.length,
    latestSemester: latest?.semester,
    latestSgpa: latest?.sgpa,
  );
});

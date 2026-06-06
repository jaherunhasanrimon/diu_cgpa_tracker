import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/registration_model.dart';
import '../repository/registration_repository.dart';

import '../../academic/domain/curriculum_engine.dart';
import '../../cgpa/data/models/semester_result_model.dart';

class RegistrationState {
  final String university;
  final String name;
  final String email;

  final String department;
  final String admissionTerm;
  final String year;

  final int completedSemester;

  final List<SemesterResultModel> results;

  final Map<int, double> sgpaHistory;

  RegistrationState({
    this.university = '',
    this.name = '',
    this.email = '',

    this.department = '',
    this.admissionTerm = '',
    this.year = '',

    this.completedSemester = 0,

    this.results = const [],

    this.sgpaHistory = const {},
  });

  RegistrationState copyWith({
    String? university,
    String? name,
    String? email,

    String? department,
    String? admissionTerm,
    String? year,

    int? completedSemester,

    List<SemesterResultModel>? results,
    Map<int, double>? sgpaHistory,
  }) {
    return RegistrationState(
      university: university ?? this.university,
      name: name ?? this.name,
      email: email ?? this.email,

      department: department ?? this.department,
      admissionTerm: admissionTerm ?? this.admissionTerm,

      year: year ?? this.year,

      completedSemester: completedSemester ?? this.completedSemester,

      results: results ?? this.results,
      sgpaHistory: sgpaHistory ?? this.sgpaHistory,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(RegistrationState());

  void saveAcademic({
    required String department,
    required String term,
    required String year,
    required int completedSemester,
    required List<SemesterResultModel> results,
  }) {
    final nextHistory = _historyFromResults(
      results,
      maxSemester: completedSemester,
    );

    final nextState = state.copyWith(
      department: department,
      admissionTerm: term,
      year: year,
      completedSemester: completedSemester,
      sgpaHistory: nextHistory,
    );

    state = nextState.copyWith(
      results: _rebuildResults(
        sourceState: nextState,
        sgpaHistory: nextHistory,
      ),
    );
  }

  void setAcademicInfo({
    required String department,
    required String admissionTerm,
    required int completedSemester,
  }) {
    final nextState = state.copyWith(
      department: department,
      admissionTerm: admissionTerm,
      completedSemester: completedSemester,
    );

    state = nextState.copyWith(
      results: _rebuildResults(
        sourceState: nextState,
        sgpaHistory: nextState.sgpaHistory,
      ),
    );
  }

  void setSemesterResults(List<SemesterResultModel> results) {
    final nextHistory = _historyFromResults(
      results,
      maxSemester: state.completedSemester,
    );

    state = state.copyWith(
      sgpaHistory: nextHistory,
      results: _rebuildResults(sourceState: state, sgpaHistory: nextHistory),
    );
  }

  void updateResults(List<SemesterResultModel> results) {
    setSemesterResults(results);
  }

  void setSemesterSGPA(int semester, double sgpa) {
    if (sgpa < 0 || sgpa > 4) {
      return;
    }

    final nextHistory = {...state.sgpaHistory, semester: sgpa};

    state = state.copyWith(
      sgpaHistory: {...nextHistory},
      results: _rebuildResults(sourceState: state, sgpaHistory: nextHistory),
    );
  }

  void clearSemesterSGPA(int semester) {
    final nextHistory = Map<int, double>.from(state.sgpaHistory)
      ..remove(semester);

    state = state.copyWith(
      sgpaHistory: nextHistory,
      results: _rebuildResults(sourceState: state, sgpaHistory: nextHistory),
    );
  }

  void updateSemesterResult(int semester, double sgpa) {
    setSemesterSGPA(semester, sgpa);
  }

  void setCompletedSemester(int semester) {
    final nextHistory = Map<int, double>.from(state.sgpaHistory)
      ..removeWhere((key, value) => key > semester);

    final nextState = state.copyWith(
      completedSemester: semester,
      sgpaHistory: nextHistory,
    );

    state = nextState.copyWith(
      results: _rebuildResults(
        sourceState: nextState,
        sgpaHistory: nextHistory,
      ),
    );
  }

  bool hasCompleteSemesterResults() {
    if (state.completedSemester == 0) {
      return false;
    }

    if (state.results.length != state.completedSemester) {
      return false;
    }

    for (var semester = 1; semester <= state.completedSemester; semester++) {
      final result = state.results.where((item) => item.semester == semester);

      if (result.isEmpty) {
        return false;
      }

      if (result.first.credit <= 0) {
        return false;
      }
    }

    return true;
  }

  List<SemesterResultModel> _rebuildResults({
    required RegistrationState sourceState,
    required Map<int, double> sgpaHistory,
  }) {
    if (sourceState.admissionTerm.isEmpty ||
        sourceState.completedSemester == 0 ||
        sgpaHistory.isEmpty) {
      return const [];
    }

    final curriculum = CurriculumEngine().generatePlan(
      intake: sourceState.admissionTerm,
      currentSemester: sourceState.completedSemester,
    );

    final results = <SemesterResultModel>[];

    for (
      var semester = 1;
      semester <= sourceState.completedSemester;
      semester++
    ) {
      final sgpa = sgpaHistory[semester];

      if (sgpa == null) {
        continue;
      }

      final index = semester - 1;
      final credit = index < curriculum.length ? curriculum[index].credit : 0.0;

      results.add(
        SemesterResultModel(semester: semester, sgpa: sgpa, credit: credit),
      );
    }

    return results;
  }

  Map<int, double> _historyFromResults(
    List<SemesterResultModel> results, {
    required int maxSemester,
  }) {
    return {
      for (final result in results)
        if (result.semester <= maxSemester) result.semester: result.sgpa,
    };
  }

  Future<void> finishRegistration() async {
    final model = RegistrationModel(
      university: state.university,
      name: state.name,
      email: state.email,

      department: state.department,
      admissionTerm: state.admissionTerm,
      year: state.year,

      completedSemester: state.completedSemester,

      results: state.results,
      sgpaHistory: state.sgpaHistory,
    );

    await RegistrationRepository().save(model);
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
      return RegistrationNotifier();
    });

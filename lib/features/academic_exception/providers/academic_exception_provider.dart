import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/academic_exception_model.dart';
import '../repository/academic_exception_repository.dart';

class AcademicExceptionsNotifier extends StateNotifier<List<AcademicExceptionModel>> {
  final _repository = AcademicExceptionRepository();

  AcademicExceptionsNotifier() : super([]) {
    load();
  }

  void load() {
    state = _repository.getExceptions();
  }

  Future<void> addException(AcademicExceptionModel exception) async {
    final newState = [...state, exception];
    await _repository.save(newState);
    state = newState;
  }

  Future<void> removeException(String courseId) async {
    final newState = state.where((e) => e.courseId != courseId).toList();
    await _repository.save(newState);
    state = newState;
  }

  Future<void> toggleOverride({
    required String courseId,
    required String courseName,
    required double credit,
    required int originalSemester,
  }) async {
    final index = state.indexWhere((e) => e.courseId == courseId);
    List<AcademicExceptionModel> newState;
    if (index != -1) {
      newState = state.map((e) {
        if (e.courseId == courseId) {
          return e.copyWith(overridePrerequisite: !e.overridePrerequisite);
        }
        return e;
      }).toList();
    } else {
      newState = [
        ...state,
        AcademicExceptionModel(
          courseId: courseId,
          courseName: courseName,
          credit: credit,
          originalSemester: originalSemester,
          type: 'INCOMPLETE',
          completed: false,
          overridePrerequisite: true,
        )
      ];
    }
    await _repository.save(newState);
    state = newState;
  }

  Future<void> clear() async {
    await _repository.save([]);
    state = [];
  }
}

final academicExceptionsProvider =
    StateNotifierProvider<AcademicExceptionsNotifier, List<AcademicExceptionModel>>((ref) {
      return AcademicExceptionsNotifier();
    });

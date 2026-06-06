import '../../../core/storage/hive_service.dart';
import '../data/models/academic_exception_model.dart';

class AcademicExceptionRepository {
  static const _exceptionsKey = 'academic_exceptions';

  List<AcademicExceptionModel> getExceptions() {
    final raw = HiveService.box.get(_exceptionsKey, defaultValue: const []);
    if (raw is! List) {
      return [];
    }
    return raw
        .whereType<Map>()
        .map((e) => AcademicExceptionModel.fromMap(e))
        .toList();
  }

  Future<void> save(List<AcademicExceptionModel> exceptions) async {
    final data = exceptions.map((e) => e.toMap()).toList();
    await HiveService.box.put(_exceptionsKey, data);
  }
}

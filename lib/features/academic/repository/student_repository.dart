import '../../../core/storage/hive_service.dart';

class StudentRepository {


  Future<void> saveStudent({
    required String department,
    required String intake,
    required int semester,
    required bool isRegular,
    String? lastTrackedTerm,
  }) async {
    final current = getStudent();
    final term = lastTrackedTerm ?? current?['lastTrackedTerm']?.toString();

    await HiveService.box.put(
      'student',
      {
        'department': department,
        'intake': intake,
        'semester': semester,
        'isRegular': isRegular,
        if (term != null) 'lastTrackedTerm': term,
      },
    );
  }




  Map? getStudent(){
    if (!HiveService.isInitialized) return null;
    return HiveService.box.get(
      'student',
    );
  }

  bool hasStudent(){
    if (!HiveService.isInitialized) return false;
    return HiveService.box.containsKey(
      'student',
    );
  }



}
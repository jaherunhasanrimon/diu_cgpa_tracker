import '../../../core/storage/hive_service.dart';

class StudentRepository {


  Future<void> saveStudent({

    required String department,
    required String intake,
    required int semester,
    required bool isRegular,

  }) async {


    await HiveService.box.put(
      'student',
      {
        'department': department,
        'intake': intake,
        'semester': semester,
        'isRegular': isRegular,
      },
    );


  }




  Map? getStudent(){

    return HiveService.box.get(
      'student',
    );

  }



  bool hasStudent(){

    return HiveService.box.containsKey(
      'student',
    );

  }



}
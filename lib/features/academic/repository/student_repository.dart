import '../../../core/storage/hive_service.dart';

class StudentRepository {


  Future<void> saveStudent({

    required String department,
    required String intake,
    required int semester,

  }) async {


    await HiveService.appBox.put(
      'student',
      {
        'department': department,
        'intake': intake,
        'semester': semester,
      },
    );


  }




  Map? getStudent(){

    return HiveService.appBox.get(
      'student',
    );

  }



  bool hasStudent(){

    return HiveService.appBox.containsKey(
      'student',
    );

  }



}
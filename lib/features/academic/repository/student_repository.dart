import '../../../core/storage/hive_service.dart';

class StudentRepository {


  Future<void> saveStudent({

    required String department,
    required String intake,
    required int semester,

  }) async {


    await HiveService.box.put(
      'student',
      {
        'department': department,
        'intake': intake,
        'semester': semester,
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
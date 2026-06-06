import '../../../core/storage/hive_service.dart';
import '../data/models/registration_model.dart';


class RegistrationRepository {


  Future<void> save(
      RegistrationModel data,
      ) async {


    await HiveService.box.put(
      'registration',
      data.toMap(),
    );


  }



  RegistrationModel? get() {


    final data =
    HiveService.box.get('registration');


    if (data == null) {
      return null;
    }


    return RegistrationModel.fromMap(data);


  }


}
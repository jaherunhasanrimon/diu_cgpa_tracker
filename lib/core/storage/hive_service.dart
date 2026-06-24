import 'package:hive_flutter/hive_flutter.dart';

class HiveService {

  static late Box _box;


  static Future<void> init() async {

    await Hive.initFlutter();

    _box = await Hive.openBox(
      'diu_cgpa_tracker',
    );

  }



  static Box get box => _box;

  static set box(Box val) => _box = val;



  static Future<void> clear() async {

    await _box.clear();

  }


}
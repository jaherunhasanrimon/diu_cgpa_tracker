import 'package:flutter/material.dart';

import '../../../core/storage/hive_service.dart';
import '../data/models/semester_result_model.dart';


class CgpaRepository {

  static const _resultsKey = 'cgpa_results';


  List<SemesterResultModel> getResults(){
    if (!HiveService.isInitialized) return [];
    final raw = HiveService.box.get(
      _resultsKey,
      defaultValue: const [],
    );

    debugPrint(
      'Loaded CGPA DATA: $raw',
    );

    if (raw is! List) {
      return [];
    }

    return raw
        .whereType<Map>()
        .map((e) {
          final semester = e['semester'];
          final sgpa = e['sgpa'];
          final credit = e['credit'];

          return SemesterResultModel(
            semester: (semester as num).toInt(),
            sgpa: (sgpa as num).toDouble(),
            credit: (credit as num).toDouble(),
          );
        })
        .toList();


  }


  Future<void> save(
    List<SemesterResultModel> results,
  ) async {

    final data = results
        .map((e) => {
              'semester': e.semester,
              'sgpa': e.sgpa,
              'credit': e.credit,
            })
        .toList();

    await HiveService.box.put(
      _resultsKey,
      data,
    );


  }


}
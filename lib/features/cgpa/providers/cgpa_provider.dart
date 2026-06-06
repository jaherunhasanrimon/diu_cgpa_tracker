import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/cgpa_engine.dart';
import '../repository/cgpa_repository.dart';

final cgpaProvider = Provider<double>((ref) {
  final results = CgpaRepository().getResults();

  return CgpaEngine().calculate(results);
});

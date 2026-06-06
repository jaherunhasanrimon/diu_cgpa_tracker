import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../cgpa/domain/cgpa_engine.dart';
import '../../../providers/registration_provider.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);
    final cgpa = CgpaEngine().calculate(data.results);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review your information',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text('Department: ${data.department}'),
          Text('Completed Semester: ${data.completedSemester}'),
          const SizedBox(height: 20),
          Text(
            'Current CGPA: ${cgpa.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Semester Results'),
          const SizedBox(height: 10),
          ...data.results.map((result) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Semester ${result.semester}'),
              subtitle: Text('Credit: ${result.credit}'),
              trailing: Text(result.sgpa.toStringAsFixed(2)),
            );
          }),
        ],
      ),
    );
  }
}

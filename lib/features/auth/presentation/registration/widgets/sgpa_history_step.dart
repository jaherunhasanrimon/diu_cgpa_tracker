import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../providers/registration_provider.dart';

class SgpaHistoryStep extends ConsumerWidget {
  const SgpaHistoryStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your SGPA history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.lg),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.completedSemester,
            itemBuilder: (context, index) {
              final semester = index + 1;
              final savedSgpa = data.sgpaHistory[semester];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semester $semester',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: savedSgpa?.toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'SGPA',
                        hintText: 'Example: 3.75',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          notifier.clearSemesterSGPA(semester);
                          return;
                        }

                        final sgpa = double.tryParse(value);

                        if (sgpa == null) {
                          return;
                        }

                        notifier.setSemesterSGPA(semester, sgpa);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

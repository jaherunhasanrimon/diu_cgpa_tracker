import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../academic/domain/curriculum_engine.dart';
import '../../../providers/registration_provider.dart';

class AcademicIdentityStep extends ConsumerWidget {
  const AcademicIdentityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final supportedIntakes = CurriculumEngine().supportedIntakes();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Tell us about your academic structure.',
            style: AppTextStyles.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.xl),

          DropdownButtonFormField<String>(
            initialValue: data.department.isEmpty ? null : data.department,

            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),

            items: const [
              DropdownMenuItem(
                value: 'Computer Science & Engineering',
                child: Text('Computer Science & Engineering'),
              ),
            ],

            onChanged: (value) {
              if (value == null) return;

              notifier.setAcademicInfo(
                department: value,
                admissionTerm: data.admissionTerm,
                completedSemester: data.completedSemester,
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          DropdownButtonFormField<String>(
            initialValue: data.completedSemester == 0
                ? null
                : data.completedSemester.toString(),

            decoration: const InputDecoration(
              labelText: 'Current Semester',
              border: OutlineInputBorder(),
            ),

            items: List.generate(
              12,
              (index) => DropdownMenuItem(
                value: '${index + 1}',
                child: Text('Semester ${index + 1}'),
              ),
            ),

            onChanged: (value) {
              if (value == null) return;

              final newSem = int.tryParse(value) ?? data.completedSemester;

              if (newSem != data.completedSemester) {
                notifier.setCompletedSemester(newSem);
              }
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Program Structure',
              border: OutlineInputBorder(),
            ),

            items: const [
              DropdownMenuItem(
                value: '8',
                child: Text('Bi Semester (8 Semesters)'),
              ),

              DropdownMenuItem(
                value: '12',
                child: Text('Tri Semester (12 Semesters)'),
              ),
            ],

            onChanged: (value) {},
          ),

          const SizedBox(height: AppSpacing.lg),

          DropdownButtonFormField<String>(
            initialValue: data.admissionTerm.isEmpty
                ? null
                : data.admissionTerm,
            decoration: const InputDecoration(
              labelText: 'Admission Intake',
              border: OutlineInputBorder(),
            ),
            items: supportedIntakes
                .map(
                  (intake) =>
                      DropdownMenuItem(value: intake, child: Text(intake)),
                )
                .toList(),
            onChanged: (value) {
              if (value == null || value == data.admissionTerm) return;

              notifier.setAcademicInfo(
                department: data.department,
                admissionTerm: value,
                completedSemester: data.completedSemester,
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class AcademicIdentityStep extends StatelessWidget {
  const AcademicIdentityStep({super.key});

  @override
  Widget build(BuildContext context) {

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

            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),

            items: const [

              DropdownMenuItem(
                value: 'CSE',
                child: Text('Computer Science & Engineering'),
              ),

              DropdownMenuItem(
                value: 'SWE',
                child: Text('Software Engineering'),
              ),

            ],

            onChanged: (value) {},
          ),

          const SizedBox(height: AppSpacing.lg),

          DropdownButtonFormField<String>(
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

            onChanged: (value) {},
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

          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Intake (Optional)',
              hintText: 'e.g. Spring 2025',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
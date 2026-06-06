import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../providers/registration_provider.dart';

class SemesterProgressStep extends ConsumerWidget {
  const SemesterProgressStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final data = ref.watch(registrationProvider);

    final completedSemester = data.completedSemester;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(
          'Confirm your academic progress.',
          style: AppTextStyles.bodyMedium,
        ),

        const SizedBox(height: AppSpacing.xl),


        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(
            AppSpacing.lg,
          ),

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(16),

            boxShadow: [

              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 10,
              ),

            ],

          ),


          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [


              Text(
                'Completed Semesters',
                style: AppTextStyles.headingMedium,
              ),


              const SizedBox(
                height: AppSpacing.md,
              ),


              ListView.builder(

                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),

                itemCount: completedSemester,

                itemBuilder: (context, index) {


                  final semester = index + 1;


                  return ListTile(

                    contentPadding: EdgeInsets.zero,


                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),


                    title: Text(
                      'Semester $semester',
                    ),

                  );

                },

              ),

            ],

          ),

        ),

      ],

    );
  }
}
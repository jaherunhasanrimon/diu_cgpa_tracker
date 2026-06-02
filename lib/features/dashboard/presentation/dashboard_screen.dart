import 'package:flutter/material.dart';

import '../../academic/domain/student_profile_builder.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(
              'Dashboard Screen',
              style: AppTextStyles.headingMedium,
            ),

            const SizedBox(height: AppSpacing.lg),

            PrimaryButton(
              text: 'Continue',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
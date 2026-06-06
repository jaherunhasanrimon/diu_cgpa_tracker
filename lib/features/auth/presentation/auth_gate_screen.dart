import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class AuthGateScreen extends StatelessWidget {
  const AuthGateScreen({super.key});

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
              'Welcome to DIU CGPA Tracker',
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMedium,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Continue your academic journey with intelligent tracking and planning.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppSpacing.xxl),

            PrimaryButton(
              text: 'Create Account',

              onPressed: () {
                context.go('/register-wizard');
              },
            ),

            const SizedBox(height: AppSpacing.md),

            OutlinedButton(
              onPressed: () {
                context.go('/login');
              },

              child: const Text('Already have an account?'),
            ),
          ],
        ),
      ),
    );
  }
}
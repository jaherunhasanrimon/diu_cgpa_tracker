import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),

          child: Column(
            children: [
              const Spacer(),

              Container(
                height: 240,
                width: 240,

                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(40),
                ),

                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 120,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Track Your Academic Journey',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingLarge,
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Analyze CGPA, manage retakes, plan future semesters, and make smarter academic decisions.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),

              const Spacer(),

              PrimaryButton(
                text: 'Get Started',

                onPressed: () {
                  context.go('/auth');
                },
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

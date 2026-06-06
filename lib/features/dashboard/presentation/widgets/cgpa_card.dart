import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../cgpa/providers/cgpa_provider.dart';

class CgpaCard extends StatelessWidget {
  final CgpaSummary summary;
  final VoidCallback onTap;

  const CgpaCard({super.key, required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .04),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Current CGPA', style: AppTextStyles.bodyLarge),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    summary.cgpa.toStringAsFixed(2),
                    style: AppTextStyles.headingLarge.copyWith(
                      fontSize: 44,
                      color: AppColors.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.xs,
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      '/4.00',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(_statusText(summary.cgpa), style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(double cgpa) {
    if (summary.completedSemesters == 0) {
      return 'Add semester results to unlock progress insights.';
    }

    if (cgpa >= 3.75) {
      return 'Excellent standing. Keep protecting the margin.';
    }

    if (cgpa >= 3.25) {
      return 'Strong progress with room to plan the next lift.';
    }

    if (cgpa >= 2.5) {
      return 'Stable standing. Target planning can help the next semesters.';
    }

    return 'Needs attention. Retake and target planning should come next.';
  }
}

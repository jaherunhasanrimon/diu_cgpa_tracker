import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../academic_exception/domain/exception_engine.dart';
import '../../../../cgpa/domain/cgpa_engine.dart';
import '../../../providers/registration_provider.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);

    // Calculate adjusted results for correct review metrics
    final adjustedResults = ExceptionEngine().adjust(
      semesters: data.results,
      exceptions: data.exceptions,
    );

    final cgpa = CgpaEngine().calculate(adjustedResults);
    final completedCredits = adjustedResults.fold<double>(
      0.0,
      (total, result) => total + result.credit,
    );

    final retakesCount = data.exceptions.where((e) => e.type == 'retake').length;
    final improvementsCount = data.exceptions.where((e) => e.type == 'improvement').length;
    final droppedCount = data.exceptions.where((e) => e.type == 'dropped').length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm academic profile setup.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Overview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cgpa.toStringAsFixed(2),
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 36,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Estimated CGPA',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          completedCredits.toStringAsFixed(1),
                          style: AppTextStyles.headingMedium.copyWith(
                            fontSize: 28,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Completed Credits',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                _InfoRow(label: 'Department', value: data.department),
                _InfoRow(label: 'Intake', value: data.admissionTerm),
                _InfoRow(label: 'Current Semester', value: '${data.completedSemester + 1}'),
                _InfoRow(
                  label: 'Academic Track',
                  value: data.isRegular ? 'Regular Student' : 'Irregular Student',
                  valueColor: data.isRegular ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Exceptions Summary Card
          if (!data.isRegular) ...[
            Text(
              'Exceptions Summary',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SummaryItem(label: 'Retakes', count: retakesCount, color: AppColors.danger),
                  const Divider(height: AppSpacing.sm),
                  _SummaryItem(label: 'Improvements', count: improvementsCount, color: AppColors.warning),
                  const Divider(height: AppSpacing.sm),
                  _SummaryItem(label: 'Dropped Courses', count: droppedCount, color: AppColors.secondary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          Text(
            'Semester SGPA Results',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.results.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final result = data.results[index];
              // Get original vs adjusted credit for this semester
              final adjustedRes = adjustedResults.firstWhere((r) => r.semester == result.semester);
              final creditChanged = result.credit != adjustedRes.credit;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Semester ${result.semester}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Row(
                  children: [
                    Text('Credit: ${result.credit.toStringAsFixed(1)}'),
                    if (creditChanged) ...[
                      const Icon(Icons.arrow_right_alt, size: 16, color: AppColors.textSecondary),
                      Text(
                        '${adjustedRes.credit.toStringAsFixed(1)} (Dropped)',
                        style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  adjustedRes.sgpa.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: result.sgpa != adjustedRes.sgpa ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

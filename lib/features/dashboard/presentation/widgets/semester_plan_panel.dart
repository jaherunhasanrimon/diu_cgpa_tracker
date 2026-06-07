import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../academic/data/models/course_model.dart';
import '../../../academic_exception/data/models/student_semester_plan.dart';
import '../../../academic_exception/providers/academic_exception_provider.dart';

class SemesterPlanPanel extends ConsumerWidget {
  final StudentSemesterPlan plan;
  final String intake;

  const SemesterPlanPanel({
    super.key,
    required this.plan,
    required this.intake,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRegular = plan.regularCourses.isNotEmpty;
    final hasRetakes = plan.retakeCourses.isNotEmpty;
    final hasBlocked = plan.blockedCourses.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
              Text(
                'Semester ${plan.semester} Plan',
                style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${plan.totalCredits.toStringAsFixed(1)} Credits',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Available / Regular Courses
          if (hasRegular) ...[
            _SectionHeader(title: 'Available Courses', color: AppColors.success),
            ...plan.regularCourses.map((c) => _CourseRow(
                  course: c,
                  statusLabel: 'Curriculum',
                  statusColor: AppColors.success,
                  icon: Icons.check_circle_outline,
                )),
            const SizedBox(height: AppSpacing.md),
          ],

          // Retake Courses
          if (hasRetakes) ...[
            _SectionHeader(title: 'Suggested Retakes', color: AppColors.danger),
            ...plan.retakeCourses.map((c) => _CourseRow(
                  course: c,
                  statusLabel: 'Retake',
                  statusColor: AppColors.danger,
                  icon: Icons.replay_circle_filled,
                )),
            const SizedBox(height: AppSpacing.md),
          ],

          // Blocked Courses
          if (hasBlocked) ...[
            _SectionHeader(title: 'Blocked Prerequisites', color: AppColors.warning),
            ...plan.blockedCourses.map((c) => _BlockedCourseRow(
                  course: c,
                  targetSemester: plan.semester,
                  onOverride: () => _showOverrideDialog(context, ref, c),
                )),
          ],

          if (!hasRegular && !hasRetakes && !hasBlocked)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No courses mapped for this term.'),
              ),
            ),
        ],
      ),
    );
  }

  void _showOverrideDialog(BuildContext context, WidgetRef ref, CourseModel course) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              const Text('Prerequisite Override'),
            ],
          ),
          content: Text(
            'This course requires ${course.prerequisites.join(", ")}. '
            'Only add this course if your department has explicitly approved this exception.',
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref.read(academicExceptionsProvider.notifier).toggleOverride(
                      courseId: course.code,
                      courseName: course.title,
                      credit: course.credit,
                      originalSemester: plan.semester,
                    );
                Navigator.pop(context);
              },
              child: const Text('Add Course anyway'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseRow extends StatelessWidget {
  final CourseModel course;
  final String statusLabel;
  final Color statusColor;
  final IconData icon;

  const _CourseRow({
    required this.course,
    required this.statusLabel,
    required this.statusColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course.code}: ${course.title}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${course.credit.toStringAsFixed(1)} Credits',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedCourseRow extends StatelessWidget {
  final CourseModel course;
  final int targetSemester;
  final VoidCallback onOverride;

  const _BlockedCourseRow({
    required this.course,
    required this.targetSemester,
    required this.onOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.lock_outline, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course.code}: ${course.title}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prerequisite: Complete ${course.prerequisites.join(", ")} first',
                  style: TextStyle(
                    color: AppColors.danger.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.backgroundLight,
              foregroundColor: AppColors.primary,
              elevation: 0,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onOverride,
            child: const Text(
              'Add Anyway',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

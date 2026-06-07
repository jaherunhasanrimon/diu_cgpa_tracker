import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../academic/data/sources/cse_curriculum_source.dart';
import '../../../../academic/data/models/course_model.dart';
import '../../../../academic_exception/data/models/academic_exception_model.dart';
import '../../../providers/registration_provider.dart';

class AcademicExceptionStep extends ConsumerWidget {
  const AcademicExceptionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final completedSemester = state.completedSemester;
    final intake = state.admissionTerm;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have any failed, dropped, incomplete, or delayed courses?',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  title: 'No',
                  subtitle: 'Regular Student',
                  isSelected: state.isRegular,
                  icon: Icons.check_circle_outline,
                  onTap: () {
                    notifier.setIsRegular(true);
                    notifier.clearExceptions();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ToggleButton(
                  title: 'Yes',
                  subtitle: 'Irregular Student',
                  isSelected: !state.isRegular,
                  icon: Icons.error_outline,
                  onTap: () => notifier.setIsRegular(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.isRegular)
            _RegularBanner()
          else ...[
            Text(
              'Select courses you could not complete:',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            _CourseSelectorSection(
              intake: intake,
              completedSemester: completedSemester,
              exceptions: state.exceptions,
              onChanged: (course, originalSem, isChecked) {
                if (isChecked) {
                  notifier.addException(
                    AcademicExceptionModel(
                      courseId: course.code,
                      courseName: course.title,
                      credit: course.credit,
                      originalSemester: originalSem,
                      type: 'FAILED',
                      completed: false,
                      overridePrerequisite: false,
                    ),
                  );
                } else {
                  notifier.removeException(course.code);
                }
              },
            ),
            if (state.exceptions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Completion Status for Selected Courses',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.exceptions.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final exception = state.exceptions[index];
                  return _CompletionStatusCard(
                    exception: exception,
                    completedSemesterLimit: completedSemester,
                    onUpdate: (updated) => notifier.updateException(updated),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isSelected ? AppColors.primary : AppColors.border;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegularBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regular Academic Track',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Great! You will proceed on the standard program track. Credit counts and curriculum progress will match your intake structure perfectly.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF047857),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseSelectorSection extends StatelessWidget {
  final String intake;
  final int completedSemester;
  final List<AcademicExceptionModel> exceptions;
  final void Function(CourseModel course, int originalSem, bool isChecked) onChanged;

  const _CourseSelectorSection({
    required this.intake,
    required this.completedSemester,
    required this.exceptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(completedSemester, (semIndex) {
        final semesterNum = semIndex + 1;
        final courses = CseCurriculumSource.getCoursesForSemester(
          intake: intake,
          semesterNumber: semesterNum,
        );

        if (courses.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ExpansionTile(
            title: Text(
              'Semester $semesterNum Courses',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${courses.length} courses mapped'),
            children: courses.map((course) {
              final isChecked = exceptions.any((e) => e.courseId == course.code);

              return CheckboxListTile(
                activeColor: AppColors.primary,
                title: Text(
                  '${course.code}: ${course.title}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text('Credit: ${course.credit}'),
                value: isChecked,
                onChanged: (val) => onChanged(course, semesterNum, val ?? false),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}

class _CompletionStatusCard extends StatelessWidget {
  final AcademicExceptionModel exception;
  final int completedSemesterLimit;
  final ValueChanged<AcademicExceptionModel> onUpdate;

  const _CompletionStatusCard({
    required this.exception,
    required this.completedSemesterLimit,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final canBeCompleted = completedSemesterLimit > exception.originalSemester;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'FAILED / INCOMPLETE',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${exception.courseId}: ${exception.courseName}',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Have you already completed it?',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              Row(
                children: [
                  _StatusChoiceButton(
                    label: 'NO',
                    isSelected: !exception.completed,
                    onTap: () {
                      onUpdate(
                        exception.copyWith(
                          completed: false,
                          completedSemester: null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _StatusChoiceButton(
                    label: 'YES',
                    isSelected: exception.completed,
                    onTap: !canBeCompleted
                        ? null
                        : () {
                            onUpdate(
                              exception.copyWith(
                                completed: true,
                                completedSemester: exception.originalSemester + 1,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
          if (exception.completed && canBeCompleted) ...[
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: exception.completedSemester ?? (exception.originalSemester + 1),
              decoration: const InputDecoration(
                labelText: 'Completed In Semester',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(
                completedSemesterLimit - exception.originalSemester,
                (index) {
                  final semNum = exception.originalSemester + 1 + index;
                  return DropdownMenuItem(
                    value: semNum,
                    child: Text('Semester $semNum'),
                  );
                },
              ),
              onChanged: (value) {
                if (value == null) return;
                onUpdate(
                  exception.copyWith(completedSemester: value),
                );
              },
            ),
          ],
          if (!canBeCompleted) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cannot mark completed (failed in the latest completed semester).',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChoiceButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _StatusChoiceButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isEnabled ? AppColors.backgroundLight : AppColors.border.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isEnabled ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.5)),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
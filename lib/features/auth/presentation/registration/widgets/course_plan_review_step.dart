import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../academic/data/models/course_model.dart';
import '../../../../academic/data/sources/cse_curriculum_source.dart';
import '../../../../academic_exception/data/models/academic_exception_model.dart';
import '../../../../academic_exception/domain/exception_engine.dart';
import '../../../providers/registration_provider.dart';

/// Redesigned Course Plan Review step.
/// Matches the reference UI: clean semester plan card, ACTION REQUIRED block
/// for retakes, and PREREQUISITE BLOCKED block for overrides.
class CoursePlanReviewStep extends ConsumerWidget {
  const CoursePlanReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final intake = state.admissionTerm;
    final completedSemester = state.completedSemester;
    final exceptions = state.exceptions;

    if (intake.isEmpty || completedSemester == 0) {
      return const Center(child: Text('Please complete academic setup first.'));
    }

    final nextSemester = completedSemester + 1;
    final nextPlan = ExceptionEngine().generatePlanForSemester(
      intake: intake,
      targetSemester: nextSemester,
      exceptions: exceptions,
    );
    final pendingExceptions = exceptions.where((e) => !e.completed).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subtitle ──────────────────────────────────────────────
          Text(
            'Review your next semester courses. Failed and prerequisite '
            'courses need your attention before continuing.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Completed Semesters (compact collapsible) ─────────────
          if (completedSemester > 0) ...[
            _SectionHeader(
              label: 'COMPLETED SEMESTERS',
              icon: Icons.history_edu_rounded,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...List.generate(completedSemester, (i) {
              final semNum = i + 1;
              final courses = CseCurriculumSource.getCoursesForSemester(
                intake: intake,
                semesterNumber: semNum,
              );
              final failedIds = exceptions
                  .where((e) => e.originalSemester == semNum)
                  .map((e) => e.courseId)
                  .toSet();
              return _CompactSemesterTile(
                semesterNumber: semNum,
                courses: courses,
                failedIds: failedIds,
              );
            }),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── Next Semester Plan ─────────────────────────────────────
          _NextSemesterPlanSection(
            semesterNumber: nextSemester,
            plan: nextPlan,
            pendingExceptions: pendingExceptions,
            exceptions: exceptions,
            onRetakeToggle: (exception, scheduleForNext) {
              if (scheduleForNext) {
                notifier.updateException(
                  exception.copyWith(completedSemester: nextSemester),
                );
              } else {
                notifier.updateException(
                  exception.copyWith(clearCompletedSemester: true),
                );
              }
            },
            onOverrideToggle: (course, isOverriding) {
              final existing =
                  exceptions.where((e) => e.courseId == course.code).firstOrNull;
              if (existing != null) {
                notifier.updateException(
                  existing.copyWith(overridePrerequisite: isOverriding),
                );
              } else if (isOverriding) {
                notifier.addException(
                  AcademicExceptionModel(
                    courseId: course.code,
                    courseName: course.title,
                    credit: course.credit,
                    originalSemester: nextSemester,
                    type: 'INCOMPLETE',
                    completed: false,
                    overridePrerequisite: true,
                  ),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section Header (ALL-CAPS label + icon)
// ──────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Compact Semester Tile (collapsible, for completed semesters)
// ──────────────────────────────────────────────────────────────────────────────

class _CompactSemesterTile extends StatefulWidget {
  final int semesterNumber;
  final List<CourseModel> courses;
  final Set<String> failedIds;

  const _CompactSemesterTile({
    required this.semesterNumber,
    required this.courses,
    required this.failedIds,
  });

  @override
  State<_CompactSemesterTile> createState() => _CompactSemesterTileState();
}

class _CompactSemesterTileState extends State<_CompactSemesterTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final failCount = widget.failedIds.length;
    final passCount = widget.courses.length - failCount;
    final hasIssues = failCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 12),
              child: Row(
                children: [
                  // Semester chip
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hasIssues
                          ? AppColors.danger.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.semesterNumber}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: hasIssues ? AppColors.danger : AppColors.success,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester ${widget.semesterNumber}',
                          style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _statusPill('$passCount Passed', AppColors.success),
                            if (failCount > 0) ...[
                              const SizedBox(width: 6),
                              _statusPill('$failCount Failed', AppColors.danger),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: AppSpacing.md, endIndent: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
                  AppSpacing.md, AppSpacing.md),
              child: Column(
                children: widget.courses.map((course) {
                  final isFailed = widget.failedIds.contains(course.code);
                  return _CourseListRow(
                    course: course,
                    isFailed: isFailed,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Widget _statusPill(String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _CourseListRow extends StatelessWidget {
  final CourseModel course;
  final bool isFailed;

  const _CourseListRow({required this.course, required this.isFailed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            isFailed ? Icons.close_rounded : Icons.check_rounded,
            size: 16,
            color: isFailed ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${course.code}  ${course.title}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color:
                    isFailed ? AppColors.danger : AppColors.textPrimary,
                fontWeight:
                    isFailed ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${_creditStr(course.credit)} Credits',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _creditStr(double credit) =>
    credit % 1 == 0 ? credit.toInt().toString() : credit.toString();

// ──────────────────────────────────────────────────────────────────────────────
// Next Semester Plan Section (main redesigned section)
// ──────────────────────────────────────────────────────────────────────────────

class _NextSemesterPlanSection extends StatelessWidget {
  final int semesterNumber;
  final dynamic plan; // StudentSemesterPlan
  final List<AcademicExceptionModel> pendingExceptions;
  final List<AcademicExceptionModel> exceptions;
  final void Function(AcademicExceptionModel, bool) onRetakeToggle;
  final void Function(CourseModel, bool) onOverrideToggle;

  const _NextSemesterPlanSection({
    required this.semesterNumber,
    required this.plan,
    required this.pendingExceptions,
    required this.exceptions,
    required this.onRetakeToggle,
    required this.onOverrideToggle,
  });

  @override
  Widget build(BuildContext context) {
    final regularCourses = plan.regularCourses as List<CourseModel>;
    final retakeCourses = plan.retakeCourses as List<CourseModel>;
    final blockedCourses = plan.blockedCourses as List<CourseModel>;
    final totalCredits = plan.totalCredits as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Semester header row ────────────────────────────────────
        Row(
          children: [
            Text(
              'SEMESTER $semesterNumber PLAN',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Total Credits: ${totalCredits.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Regular Courses ────────────────────────────────────────
        if (regularCourses.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green left-border header row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                          color: AppColors.success, width: 4),
                    ),
                    color: AppColors.success.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Regular Courses (${regularCourses.length})',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    children: regularCourses.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_rounded,
                                  size: 16, color: AppColors.success),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.code}  ${c.title}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    '${_creditStr(c.credit)} Credits',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

        // ── Retakes already scheduled (from prior step) ────────────
        if (retakeCourses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 12),
                  decoration: BoxDecoration(
                    border: const Border(
                      left: BorderSide(color: AppColors.warning, width: 4),
                    ),
                    color: AppColors.warning.withValues(alpha: 0.04),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.replay_circle_filled_rounded,
                          size: 18, color: AppColors.warning),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Retakes Scheduled (${retakeCourses.length})',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    children: retakeCourses.map((c) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.replay_rounded,
                                  size: 16, color: AppColors.warning),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${c.code}  ${c.title}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5),
                                  ),
                                  Text(
                                    '${_creditStr(c.credit)} Credits',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── ACTION REQUIRED ────────────────────────────────────────
        if (pendingExceptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            label: 'ACTION REQUIRED',
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You failed ${pendingExceptions.length} previous '
                  '${pendingExceptions.length == 1 ? 'course' : 'courses'}. '
                  'Choose what you want to do.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...pendingExceptions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final isScheduled = e.completedSemester == semesterNumber;
                  return Column(
                    children: [
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: Divider(
                              height: 1,
                              color: AppColors.warning.withValues(alpha: 0.2)),
                        ),
                      _ActionRequiredCourseCard(
                        exception: e,
                        semesterNumber: semesterNumber,
                        isScheduled: isScheduled,
                        onRetake: () => onRetakeToggle(e, true),
                        onSkip: () => onRetakeToggle(e, false),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],

        // ── PREREQUISITE BLOCKED ───────────────────────────────────
        if (blockedCourses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionHeader(
            label: 'PREREQUISITE BLOCKED COURSE',
            icon: Icons.lock_rounded,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...blockedCourses.map((c) {
            final isOverridden = exceptions.any(
                (e) => e.courseId == c.code && e.overridePrerequisite);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _BlockedCourseCard(
                course: c,
                isOverridden: isOverridden,
                onToggle: (val) => onOverrideToggle(c, val),
              ),
            );
          }),
        ],

        if (regularCourses.isEmpty &&
            retakeCourses.isEmpty &&
            pendingExceptions.isEmpty &&
            blockedCourses.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No courses mapped for this semester yet.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Action Required Course Card  (retake or skip)
// ──────────────────────────────────────────────────────────────────────────────

class _ActionRequiredCourseCard extends StatelessWidget {
  final AcademicExceptionModel exception;
  final int semesterNumber;
  final bool isScheduled;
  final VoidCallback onRetake;
  final VoidCallback onSkip;

  const _ActionRequiredCourseCard({
    required this.exception,
    required this.semesterNumber,
    required this.isScheduled,
    required this.onRetake,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course info row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${exception.courseId}: ${exception.courseName}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Failed in Semester ${exception.originalSemester}  •  '
                    '${_creditStr(exception.credit)} Credits',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FAILED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Retake This Semester button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isScheduled ? null : onRetake,
            style: ElevatedButton.styleFrom(
              backgroundColor: isScheduled ? AppColors.success : AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isScheduled
                      ? Icons.check_circle_rounded
                      : Icons.replay_rounded,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isScheduled
                      ? 'Scheduled for Sem $semesterNumber'
                      : 'Retake This Semester',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (!isScheduled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'RECOMMENDED',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Skip For Now button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: isScheduled ? onSkip : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: BorderSide(
                color: isScheduled
                    ? AppColors.border
                    : AppColors.border.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Skip For Now',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Blocked Course Card  (with override button)
// ──────────────────────────────────────────────────────────────────────────────

class _BlockedCourseCard extends StatelessWidget {
  final CourseModel course;
  final bool isOverridden;
  final ValueChanged<bool> onToggle;

  const _BlockedCourseCard({
    required this.course,
    required this.isOverridden,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverridden
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.danger.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course name + BLOCKED badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${course.code}  ${course.title}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_creditStr(course.credit)} Credits',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverridden
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOverridden ? 'UNLOCKED' : 'BLOCKED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOverridden ? AppColors.primary : AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Missing prerequisite reason box
          if (course.prerequisites.isNotEmpty && !isOverridden)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${course.prerequisites.join(", ")}  Not Completed',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isOverridden)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_open_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Prerequisite overridden — department approved',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary.withValues(alpha: 0.9),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!isOverridden) ...[
            const SizedBox(height: AppSpacing.sm),
            // Solution options
            Text(
              'SOLUTION OPTIONS:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            _SolutionItem(
                index: 1,
                text:
                    'Retake ${course.prerequisites.join(", ")} first'),
            _SolutionItem(
                index: 2, text: 'Request department approval'),
          ],

          const SizedBox(height: AppSpacing.md),

          // Enable / Disable Override button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => onToggle(!isOverridden),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isOverridden ? AppColors.danger : AppColors.primary,
                side: BorderSide(
                  color: isOverridden
                      ? AppColors.danger.withValues(alpha: 0.4)
                      : AppColors.primary.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isOverridden
                    ? Icons.lock_outline_rounded
                    : Icons.lock_open_rounded,
                size: 18,
              ),
              label: Text(
                isOverridden ? 'Disable Override' : 'Enable Override',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionItem extends StatelessWidget {
  final int index;
  final String text;

  const _SolutionItem({required this.index, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index  ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

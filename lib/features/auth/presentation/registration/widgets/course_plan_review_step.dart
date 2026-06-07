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

/// Step shown only for irregular students (isRegular == false).
/// Allows semester-by-semester review of past courses (with failed ones
/// highlighted) and a prerequisite override UI for the next semester.
class CoursePlanReviewStep extends ConsumerWidget {
  const CoursePlanReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final intake = state.admissionTerm;
    final completedSemester = state.completedSemester;
    final exceptions = state.exceptions;

    // Guard: if somehow accessed while regular or before setup
    if (intake.isEmpty || completedSemester == 0) {
      return const Center(child: Text('Please complete academic setup first.'));
    }

    final nextSemester = completedSemester + 1;
    final nextPlan = ExceptionEngine().generatePlanForSemester(
      intake: intake,
      targetSemester: nextSemester,
      exceptions: exceptions,
    );
    final hasBlocked = nextPlan.blockedCourses.isNotEmpty;

    // All failed courses that are not yet completed — shown for retake scheduling
    final pendingExceptions =
        exceptions.where((e) => !e.completed).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Info Banner ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Review your courses semester by semester. '
                    'Failed courses are in red. '
                    'For your next semester, schedule which failed courses to retake '
                    'and override prerequisite blocks if department-approved.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Warning if blocked courses exist ──────────────────────
          if (hasBlocked)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${nextPlan.blockedCourses.length} course(s) in Semester $nextSemester '
                      'are blocked due to incomplete prerequisites. '
                      'Toggle the switch to override and allow enrollment.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Completed Semesters ───────────────────────────────────
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

            return _CompletedSemesterCard(
              semesterNumber: semNum,
              courses: courses,
              failedIds: failedIds,
            );
          }),

          // ── Next Semester ─────────────────────────────────────────
          _NextSemesterCard(
            semesterNumber: nextSemester,
            plan: nextPlan,
            pendingExceptions: pendingExceptions,
            exceptions: exceptions,
            onRetakeToggle: (exception, scheduleForNext) {
              if (scheduleForNext) {
                // Schedule this failed course for the next semester
                notifier.updateException(
                  exception.copyWith(completedSemester: nextSemester),
                );
              } else {
                // Unschedule — clear the planned semester
                notifier.updateException(
                  exception.copyWith(clearCompletedSemester: true),
                );
              }
            },
            onOverrideToggle: (course, isOverriding) {
              final existing = exceptions
                  .where((e) => e.courseId == course.code)
                  .firstOrNull;
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
// Completed Semester Card
// ──────────────────────────────────────────────────────────────────────────────

class _CompletedSemesterCard extends StatefulWidget {
  final int semesterNumber;
  final List<CourseModel> courses;
  final Set<String> failedIds;

  const _CompletedSemesterCard({
    required this.semesterNumber,
    required this.courses,
    required this.failedIds,
  });

  @override
  State<_CompletedSemesterCard> createState() => _CompletedSemesterCardState();
}

class _CompletedSemesterCardState extends State<_CompletedSemesterCard> {
  bool _expanded = false;

  Color get _headerColor => widget.failedIds.isEmpty
      ? AppColors.success
      : AppColors.danger;

  @override
  Widget build(BuildContext context) {
    final failCount = widget.failedIds.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? (_headerColor.withValues(alpha: 0.3))
              : AppColors.border,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                child: Row(
                  children: [
                    // Semester number chip
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _expanded
                            ? _headerColor
                            : _headerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.semesterNumber}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _expanded ? Colors.white : _headerColor,
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _statusPill(
                                '${widget.courses.length - failCount} Passed',
                                AppColors.success,
                              ),
                              if (failCount > 0) ...[
                                const SizedBox(width: 6),
                                _statusPill(
                                  '$failCount Failed',
                                  AppColors.danger,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Completed badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _expanded
                            ? _headerColor
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded courses
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Column(
                      children: [
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                          indent: AppSpacing.md,
                          endIndent: AppSpacing.md,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              AppSpacing.md),
                          child: Column(
                            children: widget.courses
                                .asMap()
                                .entries
                                .map((entry) {
                              final i = entry.key;
                              final course = entry.value;
                              final isFailed =
                                  widget.failedIds.contains(course.code);
                              final isLast =
                                  i == widget.courses.length - 1;
                              return _CompletedCourseRow(
                                index: i + 1,
                                course: course,
                                isFailed: isFailed,
                                isLast: isLast,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Completed Course Row
// ──────────────────────────────────────────────────────────────────────────────

class _CompletedCourseRow extends StatelessWidget {
  final int index;
  final CourseModel course;
  final bool isFailed;
  final bool isLast;

  const _CompletedCourseRow({
    required this.index,
    required this.course,
    required this.isFailed,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final codeColor = isFailed ? AppColors.danger : AppColors.primary;
    final titleColor =
        isFailed ? AppColors.danger : AppColors.textPrimary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index
              SizedBox(
                width: 22,
                child: Text(
                  '$index.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Code badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: codeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: codeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Title
              Expanded(
                child: Text(
                  course.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: titleColor,
                    fontWeight:
                        isFailed ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Status icon / badge
              if (isFailed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                )
              else
                const Icon(Icons.check_circle_outline,
                    size: 18, color: AppColors.success),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.border.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Next Semester Card
// ──────────────────────────────────────────────────────────────────────────────

class _NextSemesterCard extends StatelessWidget {
  final int semesterNumber;
  final dynamic plan; // StudentSemesterPlan
  final List<AcademicExceptionModel> pendingExceptions;
  final List<AcademicExceptionModel> exceptions;
  final void Function(AcademicExceptionModel exception, bool scheduleForNext)
      onRetakeToggle;
  final void Function(CourseModel course, bool isOverriding) onOverrideToggle;

  const _NextSemesterCard({
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible, not collapsible) ──
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$semesterNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        'Semester $semesterNumber',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your next semester',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${plan.totalCredits.toStringAsFixed(1)} cr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // ── Course sections ──
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Schedule Retakes ──────────────────────────────────────
                if (pendingExceptions.isNotEmpty) ...[
                  _SectionLabel(
                    label: 'Failed Courses — Schedule Retake',
                    count: pendingExceptions.length,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Small info hint
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Toggle ON to include a failed course as a retake in Semester $semesterNumber.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  ...pendingExceptions.map((e) {
                    final isScheduled = e.completedSemester == semesterNumber;
                    return _RetakeScheduleRow(
                      exception: e,
                      semesterNumber: semesterNumber,
                      isScheduled: isScheduled,
                      onToggle: (val) => onRetakeToggle(e, val),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Regular Courses ───────────────────────────────────────
                if (regularCourses.isNotEmpty) ...[
                  _SectionLabel(
                      label: 'Available Courses',
                      count: regularCourses.length,
                      color: AppColors.success),
                  const SizedBox(height: AppSpacing.xs),
                  ...regularCourses.map((c) => _PlanCourseRow(
                        course: c,
                        type: _CourseType.regular,
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Retakes Scheduled for this Semester ──────────────────
                if (retakeCourses.isNotEmpty) ...[
                  _SectionLabel(
                      label: 'Retakes Scheduled for Sem $semesterNumber',
                      count: retakeCourses.length,
                      color: const Color(0xFFD97706)),
                  const SizedBox(height: AppSpacing.xs),
                  ...retakeCourses.map((c) => _PlanCourseRow(
                        course: c,
                        type: _CourseType.retake,
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // ── Blocked Courses ───────────────────────────────────────
                if (blockedCourses.isNotEmpty) ...[
                  _SectionLabel(
                      label: 'Blocked — Override if Approved',
                      count: blockedCourses.length,
                      color: AppColors.danger),
                  const SizedBox(height: AppSpacing.xs),
                  ...blockedCourses.map((c) {
                    final isOverridden = exceptions.any(
                        (e) => e.courseId == c.code && e.overridePrerequisite);
                    return _BlockedCourseOverrideRow(
                      course: c,
                      isOverridden: isOverridden,
                      onToggle: (val) => onOverrideToggle(c, val),
                    );
                  }),
                ],

                if (pendingExceptions.isEmpty &&
                    regularCourses.isEmpty &&
                    retakeCourses.isEmpty &&
                    blockedCourses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No courses mapped for this semester yet.',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary),
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

// ──────────────────────────────────────────────────────────────────────────────
// Section Label
// ──────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Plan course types
// ──────────────────────────────────────────────────────────────────────────────

enum _CourseType { regular, retake }

class _PlanCourseRow extends StatelessWidget {
  final CourseModel course;
  final _CourseType type;

  const _PlanCourseRow({required this.course, required this.type});

  @override
  Widget build(BuildContext context) {
    final isRetake = type == _CourseType.retake;
    final badgeColor = isRetake ? AppColors.warning : AppColors.success;
    final badgeLabel = isRetake ? 'RETAKE' : 'AVAILABLE';
    final iconData = isRetake
        ? Icons.replay_circle_filled_rounded
        : Icons.check_circle_outline_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(iconData, size: 18, color: badgeColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course.code}: ${course.title}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${course.credit % 1 == 0 ? course.credit.toInt() : course.credit} Credits',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Blocked Course Row with Override Toggle
// ──────────────────────────────────────────────────────────────────────────────

class _BlockedCourseOverrideRow extends StatelessWidget {
  final CourseModel course;
  final bool isOverridden;
  final ValueChanged<bool> onToggle;

  const _BlockedCourseOverrideRow({
    required this.course,
    required this.isOverridden,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: isOverridden
            ? AppColors.primary.withValues(alpha: 0.04)
            : AppColors.danger.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverridden
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.danger.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isOverridden
                  ? Icons.lock_open_rounded
                  : Icons.lock_outline_rounded,
              size: 18,
              color: isOverridden ? AppColors.primary : AppColors.danger,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${course.code}: ${course.title}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverridden
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                // Prerequisites required
                if (course.prerequisites.isNotEmpty)
                  Text(
                    'Requires: ${course.prerequisites.join(", ")}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.danger.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (isOverridden)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Prerequisite overridden — department approved',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Override toggle
          Column(
            children: [
              Switch(
                value: isOverridden,
                onChanged: onToggle,
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                isOverridden ? 'Override\nON' : 'Override\nOFF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color:
                      isOverridden ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Retake Schedule Row
// ──────────────────────────────────────────────────────────────────────────────

class _RetakeScheduleRow extends StatelessWidget {
  final AcademicExceptionModel exception;
  final int semesterNumber;
  final bool isScheduled;
  final ValueChanged<bool> onToggle;

  const _RetakeScheduleRow({
    required this.exception,
    required this.semesterNumber,
    required this.isScheduled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: BoxDecoration(
        color: isScheduled
            ? const Color(0xFFFFFBEB) // warm amber tint when scheduled
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isScheduled
              ? const Color(0xFFFCD34D) // amber border
              : AppColors.border,
          width: isScheduled ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Failed badge for original semester
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(
                  'SEM',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${exception.originalSemester}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    height: 1.1,
                  ),
                ),
                Text(
                  'FAIL',
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Course info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exception.courseId}: ${exception.courseName}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${exception.credit % 1 == 0 ? exception.credit.toInt() : exception.credit} Credits',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isScheduled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCD34D).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '→ Retake in Sem $semesterNumber',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Toggle
          Column(
            children: [
              Switch(
                value: isScheduled,
                onChanged: onToggle,
                activeThumbColor: const Color(0xFFD97706),
                activeTrackColor: const Color(0xFFFCD34D),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                isScheduled ? 'Retake\nSem $semesterNumber' : 'Skip\nFor Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isScheduled
                      ? const Color(0xFFD97706)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

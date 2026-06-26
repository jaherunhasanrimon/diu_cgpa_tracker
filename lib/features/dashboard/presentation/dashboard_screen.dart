import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/storage/hive_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../academic/data/sources/cse_curriculum_source.dart';
import '../../academic/domain/curriculum_engine.dart';
import '../../academic/providers/academic_provider.dart';
import '../../academic_exception/domain/exception_engine.dart';
import '../../academic_exception/providers/academic_exception_provider.dart';
import '../../cgpa/providers/cgpa_provider.dart';

import 'widgets/academic_tool_card.dart';
import 'widgets/cgpa_card.dart';
import 'widgets/semester_plan_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cgpaSummaryProvider);
    final student = ref.watch(studentProvider);
    final authState = ref.watch(authProvider);

    final userName = authState.user?.name ?? 'Student';
    final studentId = authState.user?.studentId ?? '';
    final department = student?['department']?.toString() ?? 'CSE';
    final intake = student?['intake']?.toString() ?? 'Unknown intake';
    final currentSemester = (student?['semester'] as num?)?.toInt() ?? 0;
    final isRegular = student?['isRegular'] as bool? ?? true;

    final totalCredits = summary.completedCredits;
    final totalCurriculumCredits = CurriculumEngine().totalCreditForIntake(
      intake: intake,
    );
    final remainingCredits =
        (totalCurriculumCredits - totalCredits).clamp(0.0, double.infinity);

    final degreeProgress = totalCurriculumCredits == 0
        ? 0.0
        : (totalCredits / totalCurriculumCredits).clamp(0.0, 1.0);

    // Total semesters from curriculum
    final totalSemesters =
        CseCurriculumSource.getSemesters(intake: intake).length;
    final completedSemesters = summary.completedSemesters;
    final remainingSemesters =
        (totalSemesters - completedSemesters).clamp(0, totalSemesters);

    final exceptions = ref.watch(academicExceptionsProvider);
    final runningSemester = currentSemester + 1;
    final plan = ExceptionEngine().generatePlanForSemester(
      intake: intake,
      targetSemester: runningSemester,
      exceptions: exceptions,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top App Bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _AppBar(
                userName: userName,
                studentId: studentId,
                department: department,
                onReset: () async {
                  await HiveService.clear();
                  // deleteAccount() sets status → unauthenticated.
                  // RouterNotifier will redirect to /auth automatically.
                  await ref.read(authProvider.notifier).deleteAccount();
                  ref.invalidate(cgpaProvider);
                  ref.invalidate(cgpaSummaryProvider);
                  ref.invalidate(semesterResultsProvider);
                  ref.invalidate(studentProvider);
                  ref.invalidate(academicExceptionsProvider);
                },
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero CGPA Card ──────────────────────────────────
                  CgpaCard(
                    summary: summary,
                    degreeProgress: degreeProgress,
                    onTap: () => context.push('/cgpa-details'),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Academic Tools heading ──────────────────────────
                  Row(
                    children: [
                      Text(
                        'Academic Tools',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '4 tools',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Academic Tools Grid (inline) ────────────────────
                  GridView.count(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width >= 620 ? 4 : 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.05,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      AcademicToolCard(
                        icon: Icons.restart_alt_rounded,
                        title: 'Retake Analyzer',
                        subtitle: 'Find grade repair paths',
                        accentColor: Color(0xFF4F46E5),
                      ),
                      AcademicToolCard(
                        icon: Icons.track_changes_rounded,
                        title: 'Target CGPA',
                        subtitle: 'Plan your next goal',
                        accentColor: Color(0xFF06B6D4),
                      ),
                      AcademicToolCard(
                        icon: Icons.event_note_rounded,
                        title: 'Semester Planner',
                        subtitle: 'Map future credits',
                        accentColor: Color(0xFF10B981),
                      ),
                      AcademicToolCard(
                        icon: Icons.science_rounded,
                        title: 'What-if Sandbox',
                        subtitle: 'Test grade scenarios',
                        accentColor: Color(0xFFF59E0B),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Degree Progress Panel ───────────────────────────
                  _DegreeProgressPanel(
                    degreeProgress: degreeProgress,
                    completedSemesters: completedSemesters,
                    remainingSemesters: remainingSemesters,
                    completedCredits: totalCredits,
                    remainingCredits: remainingCredits,
                    isRegular: isRegular,
                    totalCurriculumCredits: totalCurriculumCredits,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Latest Result Panel ─────────────────────────────
                  _LatestResultPanel(summary: summary),

                  const SizedBox(height: AppSpacing.md),

                  // ── Next Semester Plan ──────────────────────────────
                  SemesterPlanPanel(plan: plan, intake: intake),

                  const SizedBox(height: AppSpacing.xl),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final String userName;
  final String studentId;
  final String department;
  final Future<void> Function() onReset;

  const _AppBar({
    required this.userName,
    required this.studentId,
    required this.department,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF4648D4), Color(0xFF7C5CE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.person_rounded,
                size: 22, color: Colors.white),
          ),

          // Centered title
          Expanded(
            child: Column(
              children: [
                Text(
                  userName,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  studentId.isNotEmpty ? '$department · $studentId' : department,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Right side: bell + reset
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification bell (decorative)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.notifications_none_rounded,
                    size: 20, color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Reset button
              Tooltip(
                message: 'Reset all app data',
                child: GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset App Data'),
                        content: const Text(
                          'This will erase all saved semester results and registration data. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) await onReset();
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.restart_alt_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Degree Progress Panel
// ─────────────────────────────────────────────────────────────────────────────
class _DegreeProgressPanel extends StatelessWidget {
  final double degreeProgress;
  final int completedSemesters;
  final int remainingSemesters;
  final double completedCredits;
  final double remainingCredits;
  final bool isRegular;
  final double totalCurriculumCredits;

  const _DegreeProgressPanel({
    required this.degreeProgress,
    required this.completedSemesters,
    required this.remainingSemesters,
    required this.completedCredits,
    required this.remainingCredits,
    required this.isRegular,
    required this.totalCurriculumCredits,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (degreeProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Degree Progress',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'BACHELOR OF SCIENCE',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percent%',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'OVERALL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: degreeProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEFF8),
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Stats grid — Semesters
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'COMPLETED',
                  value: '$completedSemesters Semesters',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'REMAINING',
                  value: '$remainingSemesters Semesters',
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Stats grid — Credits
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'COMPLETED CREDITS',
                  value: completedCredits.toStringAsFixed(1),
                  valueColor: AppColors.primary,
                  valueLarge: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'REMAINING',
                  value: remainingCredits.toStringAsFixed(0),
                  valueColor: AppColors.textPrimary,
                  valueLarge: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Academic Track row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F5FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Academic Track',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isRegular ? 'Regular' : 'Irregular',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool valueLarge;

  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.valueLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: valueLarge
                ? GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  )
                : GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Latest Result Panel
// ─────────────────────────────────────────────────────────────────────────────
class _LatestResultPanel extends StatelessWidget {
  final CgpaSummary summary;

  const _LatestResultPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final latestSemester = summary.latestSemester;
    final latestSgpa = summary.latestSgpa;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.query_stats_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest Result',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(
                  latestSemester == null
                      ? 'No semester result saved yet'
                      : 'Semester $latestSemester  ·  SGPA ${latestSgpa!.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary, size: 20),
        ],
      ),
    );
  }
}

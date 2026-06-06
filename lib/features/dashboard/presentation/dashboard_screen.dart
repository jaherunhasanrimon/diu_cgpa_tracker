import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/hive_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../academic/domain/curriculum_engine.dart';
import '../../academic/providers/academic_provider.dart';
import '../../cgpa/providers/cgpa_provider.dart';

import 'widgets/academic_tool_card.dart';
import 'widgets/cgpa_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cgpaSummaryProvider);
    final student = ref.watch(studentProvider);

    final department = student?['department']?.toString() ?? 'CSE';
    final intake = student?['intake']?.toString() ?? 'Unknown intake';
    final currentSemester = (student?['semester'] as num?)?.toInt() ?? 0;
    final totalCredits = summary.completedCredits;
    final totalCurriculumCredits = CurriculumEngine().totalCreditForIntake(
      intake: intake,
    );
    final degreeProgress = totalCurriculumCredits == 0
        ? 0.0
        : (totalCredits / totalCurriculumCredits).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _DashboardHeader(
                    department: department,
                    intake: intake,
                    currentSemester: currentSemester,
                    onReset: () async {
                      await HiveService.clear();

                      ref.invalidate(cgpaProvider);
                      ref.invalidate(cgpaSummaryProvider);
                      ref.invalidate(semesterResultsProvider);
                      ref.invalidate(studentProvider);

                      if (!context.mounted) {
                        return;
                      }

                      context.go('/auth');
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CgpaCard(
                    summary: summary,
                    onTap: () => context.push('/cgpa-details'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProgressPanel(
                    completedCredits: totalCredits,
                    completedSemesters: summary.completedSemesters,
                    degreeProgress: degreeProgress,
                    totalCurriculumCredits: totalCurriculumCredits,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _LatestResultPanel(summary: summary),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Academic Tools', style: AppTextStyles.headingMedium),
                  const SizedBox(height: AppSpacing.md),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverGrid.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 620 ? 4 : 2,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.02,
                children: const [
                  AcademicToolCard(
                    icon: Icons.restart_alt,
                    title: 'Retake Analyzer',
                    subtitle: 'Find grade repair paths',
                  ),
                  AcademicToolCard(
                    icon: Icons.track_changes,
                    title: 'Target CGPA',
                    subtitle: 'Plan your next goal',
                  ),
                  AcademicToolCard(
                    icon: Icons.event_note,
                    title: 'Semester Planner',
                    subtitle: 'Map future credits',
                  ),
                  AcademicToolCard(
                    icon: Icons.science_outlined,
                    title: 'What-if Sandbox',
                    subtitle: 'Test scenarios',
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

class _DashboardHeader extends StatelessWidget {
  final String department;
  final String intake;
  final int currentSemester;
  final Future<void> Function() onReset;

  const _DashboardHeader({
    required this.department,
    required this.intake,
    required this.currentSemester,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Academic Dashboard', style: AppTextStyles.headingMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('$department - $intake', style: AppTextStyles.bodyMedium),
              if (currentSemester > 0) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Current semester $currentSemester',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Reset app data',
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  final double completedCredits;
  final int completedSemesters;
  final double degreeProgress;
  final double totalCurriculumCredits;

  const _ProgressPanel({
    required this.completedCredits,
    required this.completedSemesters,
    required this.degreeProgress,
    required this.totalCurriculumCredits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Completed credits',
                  value: completedCredits.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricTile(
                  label: 'Completed semesters',
                  value: completedSemesters.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: degreeProgress,
              minHeight: 9,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            totalCurriculumCredits == 0
                ? 'Curriculum progress will appear after intake data is available'
                : '${(degreeProgress * 100).toStringAsFixed(0)}% of curriculum credits completed',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: AppTextStyles.headingMedium),
          ],
        ),
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE0F2FE),
            foregroundColor: AppColors.secondary,
            child: Icon(Icons.query_stats),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latest Result', style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  latestSemester == null
                      ? 'No semester result saved yet'
                      : 'Semester $latestSemester SGPA ${latestSgpa!.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

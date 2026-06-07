import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../academic/data/sources/cse_curriculum_source.dart';
import '../../academic_exception/data/models/academic_exception_model.dart';
import '../../academic_exception/providers/academic_exception_provider.dart';
import '../providers/cgpa_provider.dart';

class CgpaDetailsScreen extends ConsumerWidget {
  const CgpaDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpa = ref.watch(cgpaProvider);
    final results = ref.watch(adjustedSemesterResultsProvider);
    final intake = ref.watch(studentIntakeProvider);
    final exceptions = ref.watch(academicExceptionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CGPA Details',
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: results.isEmpty
          ? _EmptyState()
          : CustomScrollView(
              slivers: [
                // ── Hero CGPA Banner ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _CgpaBanner(cgpa: cgpa, semesterCount: results.length),
                ),
                // ── Section Header ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
                    child: Text(
                      'Semester History',
                      style: AppTextStyles.headingMedium.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                // ── Semester Cards ────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = results[index];
                        return _SemesterExpansionCard(
                          semesterNumber: item.semester,
                          sgpa: item.sgpa,
                          credit: item.credit,
                          intake: intake,
                          exceptions: exceptions,
                          isFirst: index == 0,
                          isLast: index == results.length - 1,
                        );
                      },
                      childCount: results.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Hero CGPA Banner
// ────────────────────────────────────────────────────────────
class _CgpaBanner extends StatelessWidget {
  final double cgpa;
  final int semesterCount;

  const _CgpaBanner({required this.cgpa, required this.semesterCount});

  Color get _cgpaColor {
    if (cgpa >= 3.7) return AppColors.success;
    if (cgpa >= 3.0) return AppColors.primary;
    if (cgpa >= 2.5) return AppColors.warning;
    return AppColors.danger;
  }

  String get _cgpaLabel {
    if (cgpa >= 3.7) return 'Outstanding';
    if (cgpa >= 3.0) return 'Very Good';
    if (cgpa >= 2.5) return 'Good';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cumulative GPA',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cgpa.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _cgpaColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    _cgpaLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _StatPill(
                icon: Icons.school_outlined,
                value: '$semesterCount',
                label: 'Semesters',
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatPill(
                icon: Icons.star_outline_rounded,
                value: '4.00',
                label: 'Max GPA',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatPill(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Expandable Semester Card
// ────────────────────────────────────────────────────────────
class _SemesterExpansionCard extends StatefulWidget {
  final int semesterNumber;
  final double sgpa;
  final double credit;
  final String intake;
  final List<AcademicExceptionModel> exceptions;
  final bool isFirst;
  final bool isLast;

  const _SemesterExpansionCard({
    required this.semesterNumber,
    required this.sgpa,
    required this.credit,
    required this.intake,
    required this.exceptions,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_SemesterExpansionCard> createState() => _SemesterExpansionCardState();
}

class _SemesterExpansionCardState extends State<_SemesterExpansionCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnim;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(_expandAnim);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Color get _sgpaColor {
    if (widget.sgpa >= 3.7) return AppColors.success;
    if (widget.sgpa >= 3.0) return AppColors.primary;
    if (widget.sgpa >= 2.5) return AppColors.warning;
    return AppColors.danger;
  }

  String get _levelTerm {
    final s = widget.semesterNumber;
    final level = ((s - 1) ~/ 3) + 1;
    final term = ((s - 1) % 3) + 1;
    return 'Level $level · Term $term';
  }

  @override
  Widget build(BuildContext context) {
    final courses = CseCurriculumSource.getCoursesForSemester(
      intake: widget.intake,
      semesterNumber: widget.semesterNumber,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: _expanded ? 1.5 : 1,
        ),
        boxShadow: _expanded
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Header Row ─────────────────────────────────────
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    // Semester number circle
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _expanded
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.semesterNumber}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _expanded
                                ? Colors.white
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Title + subtitle
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
                          Text(
                            '$_levelTerm  ·  ${widget.credit.toStringAsFixed(1)} cr  ·  ${courses.length} courses',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SGPA chip
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _sgpaColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.sgpa.toStringAsFixed(2),
                            style: TextStyle(
                              color: _sgpaColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SGPA',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Expand chevron
                    RotationTransition(
                      turns: _rotateAnim,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _expanded
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Animated Course List ────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                  if (courses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'No course data available for this semester.',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md),
                      child: Column(
                        children: List.generate(courses.length, (i) {
                          final course = courses[i];
                          final isLast = i == courses.length - 1;
                          final isFailed = widget.exceptions.any((e) =>
                              e.originalSemester == widget.semesterNumber &&
                              e.courseId == course.code);
                          return _CourseRow(
                            index: i + 1,
                            code: course.code,
                            title: course.title,
                            credit: course.credit,
                            isFailed: isFailed,
                            isLast: isLast,
                          );
                        }),
                      ),
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

// ────────────────────────────────────────────────────────────
// Single Course Row inside expanded card
// ────────────────────────────────────────────────────────────
class _CourseRow extends StatelessWidget {
  final int index;
  final String code;
  final String title;
  final double credit;
  final bool isFailed;
  final bool isLast;

  const _CourseRow({
    required this.index,
    required this.code,
    required this.title,
    required this.credit,
    required this.isFailed,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index number
              SizedBox(
                width: 24,
                child: Text(
                  '$index.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Course code badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isFailed
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFailed ? AppColors.danger : AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Course title
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: isFailed ? AppColors.danger : AppColors.textPrimary,
                    fontWeight: isFailed ? FontWeight.w600 : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Credit badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFailed
                      ? AppColors.danger.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${credit % 1 == 0 ? credit.toInt() : credit} cr',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFailed ? AppColors.danger : AppColors.success,
                  ),
                ),
              ),
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

// ────────────────────────────────────────────────────────────
// Empty State
// ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined,
                size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No semester data yet',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Complete registration to see your history.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../academic_exception/domain/exception_engine.dart';
import '../../../../cgpa/domain/cgpa_engine.dart';
import '../../../providers/registration_provider.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);

    // Calculate adjusted results for accurate preview metrics
    final adjustedResults = ExceptionEngine().adjust(
      semesters: data.results,
      exceptions: data.exceptions,
    );

    final cgpa = CgpaEngine().calculate(adjustedResults);
    final completedCredits = adjustedResults.fold<double>(
      0.0,
      (total, result) => total + result.credit,
    );
    final pendingCount = data.exceptions.where((e) => !e.completed).length;
    final completedCount = data.exceptions.where((e) => e.completed).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your academic profile before finishing.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          // ── CGPA Hero Card ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.80),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 24,
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
                        'Estimated CGPA',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cgpa.toStringAsFixed(2),
                        style: GoogleFonts.outfit(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _cgpaLabel(cgpa),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatPill(
                      label: 'Credits',
                      value: completedCredits.toStringAsFixed(1),
                      icon: Icons.credit_score_rounded,
                    ),
                    const SizedBox(height: 8),
                    _StatPill(
                      label: 'Semesters',
                      value: '${data.completedSemester}',
                      icon: Icons.calendar_today_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // ── Academic Info Card ──────────────────────────────────────────
          _InfoCard(
            children: [
              _InfoRow(
                icon: Icons.school_rounded,
                label: 'Department',
                value: data.department.isEmpty ? '—' : data.department,
              ),
              _Divider(),
              _InfoRow(
                icon: Icons.auto_awesome_rounded,
                label: 'Intake',
                value: data.admissionTerm.isEmpty ? '—' : data.admissionTerm,
              ),
              _Divider(),
              _InfoRow(
                icon: Icons.layers_rounded,
                label: 'Current Semester',
                value: '${data.completedSemester + 1}',
              ),
              _Divider(),
              _InfoRow(
                icon: Icons.person_rounded,
                label: 'Academic Track',
                value: data.isRegular ? 'Regular' : 'Irregular',
                valueColor:
                    data.isRegular ? AppColors.success : AppColors.warning,
              ),
            ],
          ).animate(delay: 80.ms).fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

          // ── Exceptions summary (irregular only) ─────────────────────────
          if (!data.isRegular) ...[
            const SizedBox(height: 16),
            Text(
              'Exceptions Summary',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ).animate(delay: 120.ms).fadeIn(duration: 300.ms),
            const SizedBox(height: 8),
            _InfoCard(
              children: [
                _SummaryRow(
                  label: 'Pending Retakes',
                  count: pendingCount,
                  color: AppColors.danger,
                  icon: Icons.pending_rounded,
                ),
                _Divider(),
                _SummaryRow(
                  label: 'Completed Retakes',
                  count: completedCount,
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ).animate(delay: 140.ms).fadeIn(duration: 350.ms),
          ],

          const SizedBox(height: 16),

          // ── SGPA per semester ───────────────────────────────────────────
          Text(
            'Semester Breakdown',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 300.ms),

          const SizedBox(height: 8),

          ...adjustedResults.asMap().entries.map((entry) {
            final i = entry.key;
            final result = entry.value;
            final original = data.results.firstWhere(
              (r) => r.semester == result.semester,
              orElse: () => result,
            );
            final creditChanged = original.credit != result.credit;
            return _SgpaRow(
              semester: result.semester,
              sgpa: result.sgpa,
              credit: result.credit,
              creditChanged: creditChanged,
              originalCredit: original.credit,
            )
                .animate(delay: Duration(milliseconds: 160 + 40 * i))
                .fadeIn(duration: 280.ms)
                .slideX(begin: 0.06, end: 0);
          }),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _cgpaLabel(double cgpa) {
    if (cgpa >= 3.75) return 'Outstanding 🏆';
    if (cgpa >= 3.50) return 'Excellent ⭐';
    if (cgpa >= 3.25) return 'Very Good 👍';
    if (cgpa >= 3.00) return 'Good ✓';
    if (cgpa >= 2.50) return 'Satisfactory';
    return 'Needs improvement';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatPill({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _SummaryRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SgpaRow extends StatelessWidget {
  final int semester;
  final double sgpa;
  final double credit;
  final bool creditChanged;
  final double originalCredit;

  const _SgpaRow({
    required this.semester,
    required this.sgpa,
    required this.credit,
    required this.creditChanged,
    required this.originalCredit,
  });

  Color get _sgpaColor {
    if (sgpa >= 3.75) return AppColors.success;
    if (sgpa >= 3.00) return AppColors.primary;
    if (sgpa >= 2.50) return AppColors.warning;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Semester label
          Text(
            'Sem $semester',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Credit badge
          Text(
            creditChanged
                ? '${originalCredit.toStringAsFixed(1)} → ${credit.toStringAsFixed(1)} cr'
                : '${credit.toStringAsFixed(1)} cr',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: creditChanged ? AppColors.secondary : AppColors.textSecondary,
              fontWeight:
                  creditChanged ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          // SGPA badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _sgpaColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sgpa.toStringAsFixed(2),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _sgpaColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 0.5, color: AppColors.border);
  }
}

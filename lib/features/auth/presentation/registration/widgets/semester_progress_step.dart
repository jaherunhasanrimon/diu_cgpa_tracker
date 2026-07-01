import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../providers/registration_provider.dart';

class SemesterProgressStep extends ConsumerWidget {
  const SemesterProgressStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);
    final completedSemester = data.completedSemester;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Here are the semesters you've completed so far.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          // ── Stats banner ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.10),
                  AppColors.secondary.withValues(alpha: 0.07),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$completedSemester',
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Semesters',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Completed',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Mini progress ring using CircularProgressIndicator
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: completedSemester / 12,
                        strokeWidth: 4,
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                      ),
                      Text(
                        '${((completedSemester / 12) * 100).round()}%',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 18),

          // ── Semester tiles ──────────────────────────────────────────────
          if (completedSemester == 0)
            _EmptyState()
          else
            ...List.generate(completedSemester, (index) {
              final sem = index + 1;
              return _SemesterTile(semester: sem)
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn(duration: 280.ms)
                  .slideX(begin: 0.08, end: 0, curve: Curves.easeOut);
            }),
        ],
      ),
    );
  }
}

class _SemesterTile extends StatelessWidget {
  final int semester;
  const _SemesterTile({super.key, required this.semester});

  // Assign a subtle color per semester to give each row a unique accent
  Color get _accentColor {
    const colors = [
      Color(0xFF6366F1), // indigo
      Color(0xFF06B6D4), // cyan
      Color(0xFFF59E0B), // amber
      Color(0xFF10B981), // green
      Color(0xFF8B5CF6), // purple
      Color(0xFFF43F5E), // rose
    ];
    return colors[(semester - 1) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Colored circle with check
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Semester $semester',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Level ${((semester - 1) ~/ 3) + 1}  ·  Term ${((semester - 1) % 3) + 1}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.school_outlined,
              size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'No semesters selected yet.\nGo back and choose your current semester.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
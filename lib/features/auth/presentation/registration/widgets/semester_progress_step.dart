import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/registration_provider.dart';

// ── Onboarding design tokens ──────────────────────────────────────────────────
const _kSurface2 = Color(0xFF161D2E);
const _kPrimary  = Color(0xFF6C63FF);
const _kTxtPri   = Color(0xFFF8FAFC);
const _kTxtSec   = Color(0xFF94A3B8);
const _kBorder   = Color(0x1AFFFFFF);
const _kSuccess  = Color(0xFF10B981);

class SemesterProgressStep extends ConsumerWidget {
  const SemesterProgressStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);
    final completed = data.completedSemester;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Here are the semesters you\'ve completed so far.',
            style: GoogleFonts.inter(fontSize: 13, color: _kTxtSec, height: 1.5),
          ),

          const SizedBox(height: 16),

          // ── Stats banner ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _kSurface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Text(
                  '$completed',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Semesters',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: _kTxtSec)),
                    Text('Completed',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kTxtPri,
                        )),
                  ],
                ),
                const Spacer(),
                // Mini progress ring
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: completed / 12,
                      strokeWidth: 3.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      color: _kPrimary,
                    ),
                    Text(
                      '${((completed / 12) * 100).round()}%',
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                  ]),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 340.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 14),

          // ── Semester tiles ───────────────────────────────────────────────
          if (completed == 0)
            _EmptyState()
          else
            ...List.generate(completed, (i) {
              return _SemesterTile(semester: i + 1)
                  .animate(delay: Duration(milliseconds: 45 * i))
                  .fadeIn(duration: 280.ms)
                  .slideX(begin: 0.06, end: 0, curve: Curves.easeOut);
            }),
        ],
      ),
    );
  }
}

class _SemesterTile extends StatelessWidget {
  final int semester;
  const _SemesterTile({required this.semester});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Check circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _kSuccess, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester $semester',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTxtPri),
                ),
                Text(
                  'Level ${((semester - 1) ~/ 3) + 1}  ·  Term ${((semester - 1) % 3) + 1}',
                  style: GoogleFonts.inter(fontSize: 11, color: _kTxtSec),
                ),
              ],
            ),
          ),
          // Done badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _kSuccess,
                  fontWeight: FontWeight.w700),
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
          const SizedBox(height: 24),
          Icon(Icons.school_outlined,
              size: 44, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Text(
            'No semesters selected yet.\nGo back and choose your current semester.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: _kTxtSec, height: 1.5),
          ),
        ],
      ),
    );
  }
}
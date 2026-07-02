import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../academic_exception/domain/exception_engine.dart';
import '../../../../cgpa/domain/cgpa_engine.dart';
import '../../../providers/registration_provider.dart';

// ── Onboarding design tokens ──────────────────────────────────────────────────
const _kSurface2 = Color(0xFF161D2E);
const _kSurface3 = Color(0xFF1E2A3E);
const _kPrimary  = Color(0xFF6C63FF);
const _kTxtPri   = Color(0xFFF8FAFC);
const _kTxtSec   = Color(0xFF94A3B8);
const _kTxtDis   = Color(0xFF64748B);
const _kBorder   = Color(0x1AFFFFFF);
const _kSuccess  = Color(0xFF10B981);
const _kWarning  = Color(0xFFF59E0B);
const _kError    = Color(0xFFEF4444);

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(registrationProvider);

    final adjusted = ExceptionEngine().adjust(
      semesters: data.results,
      exceptions: data.exceptions,
    );
    final cgpa = CgpaEngine().calculate(adjusted);
    final credits =
        adjusted.fold<double>(0.0, (t, r) => t + r.credit);
    final pending = data.exceptions.where((e) => !e.completed).length;
    final done    = data.exceptions.where((e) => e.completed).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review your academic profile before finishing.',
            style: GoogleFonts.inter(
                fontSize: 13, color: _kTxtSec, height: 1.5),
          ),

          const SizedBox(height: 16),

          // ── CGPA hero card (dark glass) ──────────────────────────────────
          _CgpaCard(cgpa: cgpa, credits: credits, semesters: data.completedSemester)
              .animate().fadeIn(duration: 380.ms).slideY(begin: 0.08, end: 0),

          const SizedBox(height: 14),

          // ── Academic info ────────────────────────────────────────────────
          _SectionCard(
            children: [
              _Row(label: 'Department',      value: data.department.isEmpty ? '—' : data.department),
              _Divider(),
              _Row(label: 'Intake',          value: data.admissionTerm.isEmpty ? '—' : data.admissionTerm),
              _Divider(),
              _Row(label: 'Current Semester', value: '${data.completedSemester + 1}'),
              _Divider(),
              _Row(
                label: 'Academic Track',
                value: data.isRegular ? 'Regular' : 'Irregular',
                valueColor:
                    data.isRegular ? _kSuccess : _kWarning,
              ),
            ],
          ).animate(delay: 60.ms).fadeIn(duration: 340.ms),

          // ── Exceptions summary (irregular only) ──────────────────────────
          if (!data.isRegular) ...[
            const SizedBox(height: 14),
            _Label('Exceptions'),
            const SizedBox(height: 8),
            _SectionCard(
              children: [
                _CountRow(label: 'Pending Retakes',   count: pending, color: _kError),
                _Divider(),
                _CountRow(label: 'Completed Retakes', count: done,    color: _kSuccess),
              ],
            ).animate(delay: 100.ms).fadeIn(duration: 340.ms),
          ],

          const SizedBox(height: 14),

          // ── SGPA breakdown ───────────────────────────────────────────────
          _Label('Semester Breakdown'),
          const SizedBox(height: 8),

          ...adjusted.asMap().entries.map((entry) {
            final i      = entry.key;
            final result = entry.value;
            final orig   = data.results.firstWhere(
                (r) => r.semester == result.semester,
                orElse: () => result);
            return _SgpaRow(
              semester: result.semester,
              sgpa: result.sgpa,
              credit: result.credit,
              creditChanged: orig.credit != result.credit,
              originalCredit: orig.credit,
            )
                .animate(delay: Duration(milliseconds: 120 + 35 * i))
                .fadeIn(duration: 260.ms)
                .slideX(begin: 0.05, end: 0);
          }),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CGPA hero card — dark glass, no neon gradient
// ─────────────────────────────────────────────────────────────────────────────

class _CgpaCard extends StatelessWidget {
  final double cgpa;
  final double credits;
  final int semesters;
  const _CgpaCard(
      {required this.cgpa, required this.credits, required this.semesters});

  String get _label {
    if (cgpa >= 3.75) return 'Outstanding';
    if (cgpa >= 3.50) return 'Excellent';
    if (cgpa >= 3.25) return 'Very Good';
    if (cgpa >= 3.00) return 'Good';
    if (cgpa >= 2.50) return 'Satisfactory';
    return 'Needs Improvement';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        // Very subtle primary tint in the top layer
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _kPrimary.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: CGPA number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated CGPA',
                  style: GoogleFonts.inter(fontSize: 11, color: _kTxtDis),
                ),
                const SizedBox(height: 4),
                Text(
                  cgpa.toStringAsFixed(2),
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w800,
                    color: _kTxtPri,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kPrimary.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    _label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: stat pills
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniStat(
                  label: 'Credits',
                  value: credits.toStringAsFixed(1)),
              const SizedBox(height: 8),
              _MiniStat(
                  label: 'Semesters',
                  value: '$semesters'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _kSurface3,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _kTxtPri)),
          Text(label,
              style: GoogleFonts.inter(fontSize: 10, color: _kTxtSec)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(children: children),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Row widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kTxtSec,
            letterSpacing: 0.2));
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 13, color: _kTxtSec)),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? _kTxtPri,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _CountRow(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(fontSize: 13, color: _kTxtSec)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color),
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
    if (sgpa >= 3.75) return _kSuccess;
    if (sgpa >= 3.00) return _kPrimary;
    if (sgpa >= 2.50) return _kWarning;
    return _kError;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Text(
            'Sem $semester',
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kTxtPri),
          ),
          const SizedBox(width: 8),
          Text(
            creditChanged
                ? '${originalCredit.toStringAsFixed(1)}→${credit.toStringAsFixed(1)} cr'
                : '${credit.toStringAsFixed(1)} cr',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: creditChanged ? _kWarning : _kTxtDis,
              fontWeight:
                  creditChanged ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _sgpaColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              sgpa.toStringAsFixed(2),
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _sgpaColor),
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
    return const Divider(height: 1, thickness: 0.5, color: Color(0x1AFFFFFF));
  }
}

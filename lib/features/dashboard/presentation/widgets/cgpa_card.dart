import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../cgpa/providers/cgpa_provider.dart';

/// Premium hero CGPA card — matches the design mockup.
///
/// Reads semester history from [adjustedSemesterResultsProvider] directly
/// so no business-logic changes are needed.
class CgpaCard extends ConsumerWidget {
  final CgpaSummary summary;
  final double degreeProgress;
  final VoidCallback onTap;

  const CgpaCard({
    super.key,
    required this.summary,
    required this.degreeProgress,
    required this.onTap,
  });

  // ── Status badge ─────────────────────────────────────────────────────────
  String get _statusLabel {
    if (summary.completedSemesters == 0) return 'No Data Yet';
    final c = summary.cgpa;
    if (c >= 3.75) return 'Excellent Standing';
    if (c >= 3.25) return 'Strong Progress';
    if (c >= 2.5) return 'Stable Standing';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(adjustedSemesterResultsProvider);
    final sorted = [...results]..sort((a, b) => a.semester.compareTo(b.semester));
    final sgpaHistory = sorted.map((r) => r.sgpa).toList();

    // Best semester
    int? bestSemester;
    if (sorted.isNotEmpty) {
      final best = sorted.reduce((a, b) => a.sgpa >= b.sgpa ? a : b);
      bestSemester = best.semester;
    }

    // Improvement vs previous semester
    String? improvementText;
    bool improving = true;
    if (sgpaHistory.length >= 2) {
      final diff = sgpaHistory.last - sgpaHistory[sgpaHistory.length - 2];
      improving = diff >= 0;
      final sign = diff >= 0 ? '+' : '';
      improvementText = '$sign${diff.toStringAsFixed(2)} improvement from last semester';
    }

    final degreePercent = (degreeProgress * 100).round();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A3BC8), Color(0xFF5A5CE8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A3BC8).withValues(alpha: 0.40),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative blob
              Positioned(
                right: -24,
                top: -24,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Row 1: CGPA + Arc ring ──────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT CGPA',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.70),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    summary.cgpa.toStringAsFixed(2),
                                    style: GoogleFonts.outfit(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 5, bottom: 7),
                                    child: Text(
                                      '/ 4.00',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white
                                            .withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Degree progress arc ring
                        _DegreeProgressRing(
                          progress: degreeProgress,
                          label: '$degreePercent%',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Status badge ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Improvement label ───────────────────────────────
                    if (improvementText != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            improving
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            improvementText,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // ── Mini trend chart ────────────────────────────────
                    if (sgpaHistory.length >= 2) ...[
                      SizedBox(
                        height: 64,
                        child: _MiniTrendChart(history: sgpaHistory),
                      ),
                      const SizedBox(height: 6),
                      _SemesterAxisLabels(count: sgpaHistory.length),
                    ],

                    // ── Best performance card ───────────────────────────
                    if (bestSemester != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Your highest performance was Semester $bestSemester',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // ── Bottom divider + credits row ─────────────────────
                    Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.65)),
                        const SizedBox(width: 6),
                        Text(
                          '${summary.completedCredits.toStringAsFixed(1)} / — Credits',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Icon(Icons.open_in_new_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.75)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Degree-progress arc ring (right side of hero card)
// ─────────────────────────────────────────────────────────────────────────────
class _DegreeProgressRing extends StatelessWidget {
  final double progress;
  final String label;

  const _DegreeProgressRing({required this.progress, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _ArcPainter(progress: progress),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'DEGREE\nPROGRESS',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.60),
            letterSpacing: 0.6,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  const _ArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini SGPA trend chart
// ─────────────────────────────────────────────────────────────────────────────
class _MiniTrendChart extends StatelessWidget {
  final List<double> history;
  const _MiniTrendChart({required this.history});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrendPainter(history: history),
      size: const Size(double.infinity, 64),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> history;
  const _TrendPainter({required this.history});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final minVal = history.reduce(math.min);
    final maxVal = history.reduce(math.max);
    final range = (maxVal - minVal).abs().clamp(0.2, 4.0);

    List<Offset> pts = [];
    for (int i = 0; i < history.length; i++) {
      final x = (i / (history.length - 1)) * size.width;
      final norm = (history[i] - (minVal - 0.15)) / (range + 0.3);
      final y = size.height - (norm * size.height * 0.75 + size.height * 0.1);
      pts.add(Offset(x, y));
    }

    // Gradient fill
    final fillPath = Path()
      ..moveTo(pts.first.dx, size.height)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      fillPath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    fillPath
      ..lineTo(pts.last.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      linePath.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (int i = 0; i < pts.length; i++) {
      final p = pts[i];
      final isLast = i == pts.length - 1;
      canvas.drawCircle(p, isLast ? 5 : 3,
          Paint()..color = Colors.white..style = PaintingStyle.fill);
      if (isLast) {
        canvas.drawCircle(
            p,
            8,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.25)
              ..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.history != history;
}

// ─────────────────────────────────────────────────────────────────────────────
// Semester axis labels
// ─────────────────────────────────────────────────────────────────────────────
class _SemesterAxisLabels extends StatelessWidget {
  final int count;
  const _SemesterAxisLabels({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(count, (i) {
        final isLast = i == count - 1;
        return Text(
          'Sem ${i + 1}',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
            color: isLast
                ? Colors.white
                : Colors.white.withValues(alpha: 0.45),
          ),
        );
      }),
    );
  }
}

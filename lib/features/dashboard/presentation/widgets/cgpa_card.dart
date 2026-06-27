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
                          Expanded(
                            child: Text(
                              improvementText,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                            const Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your highest performance was Semester $bestSemester',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
// Interactive SGPA Trend Chart
// ─────────────────────────────────────────────────────────────────────────────

/// Self-contained interactive trend chart.
/// Drag or tap anywhere on the chart to snap the selection to the nearest
/// semester point. A floating tooltip shows the SGPA; the axis label below
/// highlights the active semester. Pointer-up clears the selection.
class _InteractiveTrendChart extends StatefulWidget {
  final List<double> history;
  const _InteractiveTrendChart({required this.history});

  @override
  State<_InteractiveTrendChart> createState() => _InteractiveTrendChartState();
}

class _InteractiveTrendChartState extends State<_InteractiveTrendChart> {
  int? _activeIndex; // null = no selection

  void _updateFromLocal(Offset local, Size size) {
    if (widget.history.length < 2) return;
    final step = size.width / (widget.history.length - 1);
    int nearest = (local.dx / step).round()
        .clamp(0, widget.history.length - 1);
    if (_activeIndex != nearest) setState(() => _activeIndex = nearest);
  }

  void _clearSelection() => setState(() => _activeIndex = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      const chartH = 72.0;
      const labelH = 20.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _updateFromLocal(d.localPosition, Size(w, chartH)),
        onTapUp: (_) => _clearSelection(),
        onPanStart: (d) => _updateFromLocal(d.localPosition, Size(w, chartH)),
        onPanUpdate: (d) => _updateFromLocal(d.localPosition, Size(w, chartH)),
        onPanEnd: (_) => _clearSelection(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart area
            SizedBox(
              height: chartH,
              width: w,
              child: CustomPaint(
                painter: _InteractiveTrendPainter(
                  history: widget.history,
                  activeIndex: _activeIndex,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Axis labels
            SizedBox(
              height: labelH,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.history.length, (i) {
                  final isActive = _activeIndex == i;
                  final isLast =
                      i == widget.history.length - 1 && _activeIndex == null;
                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: GoogleFonts.inter(
                      fontSize: isActive ? 11 : 10,
                      fontWeight: (isActive || isLast)
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                    ),
                    child: Text('Sem ${i + 1}'),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _InteractiveTrendPainter extends CustomPainter {
  final List<double> history;
  final int? activeIndex;

  const _InteractiveTrendPainter({
    required this.history,
    required this.activeIndex,
  });

  // Converts history values → canvas Offsets
  List<Offset> _buildPoints(Size size) {
    final minVal = history.reduce(math.min);
    final maxVal = history.reduce(math.max);
    final range = (maxVal - minVal).abs().clamp(0.2, 4.0);
    return List.generate(history.length, (i) {
      final x = history.length == 1
          ? size.width / 2
          : (i / (history.length - 1)) * size.width;
      final norm = (history[i] - (minVal - 0.15)) / (range + 0.3);
      final y = size.height - (norm * size.height * 0.75 + size.height * 0.1);
      return Offset(x, y);
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;
    final pts = _buildPoints(size);

    // ── Gradient fill ───────────────────────────────────────────────────────
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
            Colors.white.withValues(alpha: activeIndex != null ? 0.15 : 0.28),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // ── Line ────────────────────────────────────────────────────────────────
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
        ..color = Colors.white.withValues(
            alpha: activeIndex != null ? 0.55 : 1.0)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Default dots ────────────────────────────────────────────────────────
    for (int i = 0; i < pts.length; i++) {
      if (activeIndex == i) continue; // drawn later
      final isLast = i == pts.length - 1 && activeIndex == null;
      canvas.drawCircle(
        pts[i],
        isLast ? 5 : 3,
        Paint()
          ..color = Colors.white.withValues(
              alpha: activeIndex != null ? 0.35 : 1.0)
          ..style = PaintingStyle.fill,
      );
      if (isLast && activeIndex == null) {
        canvas.drawCircle(
          pts[i],
          8,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.20)
            ..style = PaintingStyle.fill,
        );
      }
    }

    // ── Active selection ────────────────────────────────────────────────────
    if (activeIndex != null) {
      final ai = activeIndex!;
      final ap = pts[ai];
      final sgpa = history[ai];

      // Vertical dashed indicator line
      const dashH = 5.0;
      const gap = 3.0;
      double y = 0;
      final dashPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.50)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      while (y < size.height) {
        canvas.drawLine(Offset(ap.dx, y),
            Offset(ap.dx, math.min(y + dashH, size.height)), dashPaint);
        y += dashH + gap;
      }

      // Glow ring
      canvas.drawCircle(
        ap,
        14,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        ap,
        9,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      // Active dot
      canvas.drawCircle(
        ap,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // ── Floating tooltip ────────────────────────────────────────────────
      const tooltipPadH = 10.0;
      const tooltipPadV = 6.0;
      final label = 'Sem ${ai + 1}  ·  ${sgpa.toStringAsFixed(2)}';

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final tW = textPainter.width + tooltipPadH * 2;
      final tH = textPainter.height + tooltipPadV * 2;
      const arrowH = 5.0;
      const tipY = 8.0; // gap above dot

      // Box position — clamp so it never overflows left/right
      double boxLeft = ap.dx - tW / 2;
      boxLeft = boxLeft.clamp(0.0, size.width - tW);
      final boxTop = ap.dy - tH - arrowH - tipY;

      // Tooltip rounded rect
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(boxLeft, boxTop, tW, tH),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.22)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.45)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );

      // Arrow pointer
      final arrowTipX = ap.dx.clamp(boxLeft + 10, boxLeft + tW - 10);
      final arrowPath = Path()
        ..moveTo(arrowTipX - 5, boxTop + tH)
        ..lineTo(arrowTipX, boxTop + tH + arrowH)
        ..lineTo(arrowTipX + 5, boxTop + tH)
        ..close();
      canvas.drawPath(
          arrowPath,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.22)
            ..style = PaintingStyle.fill);

      // Text
      textPainter.paint(
        canvas,
        Offset(boxLeft + tooltipPadH, boxTop + tooltipPadV),
      );
    }
  }

  @override
  bool shouldRepaint(_InteractiveTrendPainter old) =>
      old.history != history || old.activeIndex != activeIndex;
}

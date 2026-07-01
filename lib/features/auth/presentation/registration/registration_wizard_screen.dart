import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../academic/repository/student_repository.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../academic_exception/providers/academic_exception_provider.dart';
import '../../../cgpa/repository/cgpa_repository.dart';
import '../../../cgpa/providers/cgpa_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/registration_provider.dart';
import '../../providers/auth_provider.dart';

import 'widgets/academic_identity_step.dart' as identity_step;
import 'widgets/semester_progress_step.dart' as semester_step;
import 'widgets/sgpa_history_step.dart' as sgpa_step;
import 'widgets/academic_exception_step.dart' as exception_step;
import 'widgets/course_plan_review_step.dart' as plan_review_step;
import 'widgets/review_step.dart' as review_step;

// ─────────────────────────────────────────────────────────────────────────────
// Step metadata — icon, color, title, subtitle for each of the 6 widget slots
// ─────────────────────────────────────────────────────────────────────────────

class _StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const _kStepData = [
  _StepInfo(
    title: 'Academic Identity',
    subtitle: 'Tell us who you are',
    icon: Icons.school_rounded,
    color: Color(0xFF6366F1),
  ),
  _StepInfo(
    title: 'Semester Progress',
    subtitle: 'Your academic journey so far',
    icon: Icons.calendar_today_rounded,
    color: Color(0xFF06B6D4),
  ),
  _StepInfo(
    title: 'SGPA History',
    subtitle: 'Enter your semester scores',
    icon: Icons.bar_chart_rounded,
    color: Color(0xFFF59E0B),
  ),
  _StepInfo(
    title: 'Academic Exceptions',
    subtitle: 'Any special course cases?',
    icon: Icons.tune_rounded,
    color: Color(0xFFF43F5E),
  ),
  _StepInfo(
    title: 'Course Plan Review',
    subtitle: 'Fine-tune your custom plan',
    icon: Icons.checklist_rounded,
    color: Color(0xFF8B5CF6),
  ),
  _StepInfo(
    title: 'Final Review',
    subtitle: "Almost there — confirm it all",
    icon: Icons.check_circle_rounded,
    color: Color(0xFF10B981),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RegistrationWizardScreen extends ConsumerStatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  ConsumerState<RegistrationWizardScreen> createState() =>
      _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState
    extends ConsumerState<RegistrationWizardScreen> {
  int currentStep = 0;
  bool _isFinishing = false;

  // ── Step routing ─────────────────────────────────────────────────────────

  /// Maps logical step position → widget slot index (0..5).
  List<int> _effectiveIndices(bool isRegular) =>
      isRegular ? [0, 1, 2, 3, 5] : [0, 1, 2, 3, 4, 5];

  Widget _buildStepWidget(int widgetIndex) => switch (widgetIndex) {
        0 => const identity_step.AcademicIdentityStep(),
        1 => const semester_step.SemesterProgressStep(),
        2 => const sgpa_step.SgpaHistoryStep(),
        3 => const exception_step.AcademicExceptionStep(),
        4 => const plan_review_step.CoursePlanReviewStep(),
        5 => const review_step.ReviewStep(),
        _ => const SizedBox.shrink(),
      };

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final authUser = ref.watch(authProvider).user;

    // Hydrate student ID from auth if wizard opened fresh
    if (authUser != null &&
        authUser.studentId.isNotEmpty &&
        regState.studentId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(registrationProvider.notifier).setStudentId(authUser.studentId);
      });
    }

    final effectiveIndices = _effectiveIndices(regState.isRegular);
    final totalSteps = effectiveIndices.length;

    final safeStep = currentStep.clamp(0, totalSteps - 1);
    if (safeStep != currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => currentStep = safeStep);
      });
    }

    final widgetIndex = effectiveIndices[safeStep];
    final isLastStep = safeStep == totalSteps - 1;
    final stepData = _kStepData[widgetIndex];
    final progress = (safeStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // ── Decorative background blobs ────────────────────────────────
          Positioned(
            top: -120,
            left: -80,
            child: _Blob(size: 320, color: stepData.color.withValues(alpha: 0.16)),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: _Blob(size: 240, color: AppColors.secondary.withValues(alpha: 0.10)),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _TopBar(
                  canGoBack: safeStep > 0 && !_isFinishing,
                  stepData: stepData,
                  currentStep: safeStep,
                  totalSteps: totalSteps,
                  onBack: () => setState(() => currentStep = safeStep - 1),
                ),

                const SizedBox(height: 12),

                // Progress bar + step dots
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ProgressSection(
                    progress: progress,
                    effectiveIndices: effectiveIndices,
                    currentStep: safeStep,
                    stepData: stepData,
                  ),
                ),

                const SizedBox(height: 16),

                // Animated step header (fades + slides on step change)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  ),
                  child: _StepHeader(
                    key: ValueKey(widgetIndex),
                    stepData: stepData,
                  ),
                ),

                const SizedBox(height: 12),

                // Step content — glass card + AnimatedSwitcher
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.97, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        ),
                      ),
                      child: _StepCard(
                        key: ValueKey(safeStep),
                        child: _buildStepWidget(widgetIndex),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Navigation row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _NavigationRow(
                    canGoBack: safeStep > 0 && !_isFinishing,
                    isLastStep: isLastStep,
                    isLoading: _isFinishing,
                    stepColor: stepData.color,
                    onBack: () => setState(() => currentStep = safeStep - 1),
                    onContinue: () => _handleContinue(
                      safeStep: safeStep,
                      widgetIndex: widgetIndex,
                      isLastStep: isLastStep,
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

  // ── Business logic ───────────────────────────────────────────────────────

  Future<void> _handleContinue({
    required int safeStep,
    required int widgetIndex,
    required bool isLastStep,
  }) async {
    final data = ref.read(registrationProvider);

    // ── Step 0: Academic Identity validation ──────────────────────────
    if (safeStep == 0) {
      if (data.department.isEmpty ||
          data.completedSemester == 0 ||
          data.studentId.isEmpty) {
        _showSnack(
            'Please complete your Student ID, department, and current semester');
        return;
      }
    }

    // ── Step 2: SGPA completeness check ──────────────────────────────
    if (widgetIndex == 2) {
      final isComplete =
          ref.read(registrationProvider.notifier).hasCompleteSemesterResults();
      if (!isComplete) {
        _showSnack('Please enter SGPA for all completed semesters');
        return;
      }
    }

    // ── Finish ────────────────────────────────────────────────────────
    if (isLastStep) {
      setState(() => _isFinishing = true);
      try {
        final repo = StudentRepository();
        final cgpaRepo = CgpaRepository();

        await ref.read(registrationProvider.notifier).finishRegistration();
        await cgpaRepo.save(data.results);
        await repo.saveStudent(
          department: data.department,
          intake: data.admissionTerm,
          semester: data.completedSemester,
          isRegular: data.isRegular,
        );

        ref.invalidate(cgpaProvider);
        ref.invalidate(cgpaSummaryProvider);
        ref.invalidate(semesterResultsProvider);
        ref.invalidate(studentProvider);
        ref.invalidate(academicExceptionsProvider);

        if (!context.mounted) return;
        await ref.read(authProvider.notifier).markProfileComplete(
              studentId: data.studentId,
              department: data.department,
            );
      } finally {
        if (mounted) setState(() => _isFinishing = false);
      }
    } else {
      setState(() => currentStep = safeStep + 1);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool canGoBack;
  final _StepInfo stepData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _TopBar({
    required this.canGoBack,
    required this.stepData,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          // Back button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: canGoBack
                ? IconButton(
                    key: const ValueKey('back'),
                    onPressed: onBack,
                    icon: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('no-back'), width: 48),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIU CGPA Tracker',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Academic Setup',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Step counter pill — color animates with current step
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: stepData.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: stepData.color.withValues(alpha: 0.40),
              ),
            ),
            child: Text(
              '${currentStep + 1} of $totalSteps',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: stepData.color.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress bar + step dots
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final double progress;
  final List<int> effectiveIndices;
  final int currentStep;
  final _StepInfo stepData;

  const _ProgressSection({
    required this.progress,
    required this.effectiveIndices,
    required this.currentStep,
    required this.stepData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient animated progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 5,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stepData.color,
                          stepData.color.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Step pill dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: effectiveIndices.asMap().entries.map((entry) {
            final stepIdx = entry.key;
            final widgetIdx = entry.value;
            final meta = _kStepData[widgetIdx];
            final isPast = stepIdx < currentStep;
            final isCurrent = stepIdx == currentStep;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCurrent
                    ? stepData.color
                    : isPast
                        ? meta.color.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.14),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step header — icon chip + title + subtitle
// ─────────────────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final _StepInfo stepData;
  const _StepHeader({super.key, required this.stepData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Colored icon in glass pill
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: stepData.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stepData.color.withValues(alpha: 0.32)),
            ),
            child: Icon(stepData.icon, color: stepData.color, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepData.title,
                  style: GoogleFonts.outfit(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  stepData.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white54,
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

// ─────────────────────────────────────────────────────────────────────────────
// Step card — white glass container that wraps each step widget
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final Widget child;
  const _StepCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation row — Back (glass) + Continue (gradient)
// ─────────────────────────────────────────────────────────────────────────────

class _NavigationRow extends StatelessWidget {
  final bool canGoBack;
  final bool isLastStep;
  final bool isLoading;
  final Color stepColor;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _NavigationRow({
    required this.canGoBack,
    required this.isLastStep,
    required this.isLoading,
    required this.stepColor,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button — glass pill
        if (canGoBack) ...[
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      color: Colors.white.withValues(alpha: 0.55), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // Continue / Finish button — gradient
        Expanded(
          child: GestureDetector(
            onTap: isLoading ? null : onContinue,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    stepColor,
                    stepColor.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: stepColor.withValues(alpha: 0.40),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLastStep ? 'Complete Setup' : 'Continue',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLastStep
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.2, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Decorative blob (same as register screen)
// ─────────────────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
        child: const SizedBox.expand(),
      ),
    );
  }
}

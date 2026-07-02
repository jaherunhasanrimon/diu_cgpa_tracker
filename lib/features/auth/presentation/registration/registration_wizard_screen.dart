import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../academic/repository/student_repository.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../academic_exception/providers/academic_exception_provider.dart';
import '../../../cgpa/repository/cgpa_repository.dart';
import '../../../cgpa/providers/cgpa_provider.dart';
import '../../providers/registration_provider.dart';
import '../../providers/auth_provider.dart';

import 'widgets/academic_identity_step.dart' as identity_step;
import 'widgets/semester_progress_step.dart' as semester_step;
import 'widgets/sgpa_history_step.dart' as sgpa_step;
import 'widgets/academic_exception_step.dart' as exception_step;
import 'widgets/course_plan_review_step.dart' as plan_review_step;
import 'widgets/review_step.dart' as review_step;

// ── Onboarding design tokens ──────────────────────────────────────────────────
const _kBg       = Color(0xFF07111F);
const _kBgAlt    = Color(0xFF0B1730);
const _kSurface1 = Color(0xFF121826);
const _kSurface2 = Color(0xFF161D2E);
const _kSurface3 = Color(0xFF1E2A3E);
const _kPrimary  = Color(0xFF6C63FF);
const _kTxtPri   = Color(0xFFF8FAFC);
const _kTxtSec   = Color(0xFF94A3B8);
const _kTxtDis   = Color(0xFF64748B);
const _kBorder   = Color(0x1AFFFFFF);   // white 10 %
const _kSuccess  = Color(0xFF10B981);
const _kWarning  = Color(0xFFF59E0B);
const _kError    = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────────────────────
// Step metadata — single accent; individual icons only for identification
// ─────────────────────────────────────────────────────────────────────────────

class _StepMeta {
  final String title;
  final String subtitle;
  final IconData icon;
  const _StepMeta(
      {required this.title, required this.subtitle, required this.icon});
}

const _kSteps = [
  _StepMeta(
    title: 'Academic Identity',
    subtitle: 'Tell us who you are',
    icon: Icons.school_rounded,
  ),
  _StepMeta(
    title: 'Semester Progress',
    subtitle: 'Your academic journey so far',
    icon: Icons.calendar_today_rounded,
  ),
  _StepMeta(
    title: 'SGPA History',
    subtitle: 'Enter your semester scores',
    icon: Icons.bar_chart_rounded,
  ),
  _StepMeta(
    title: 'Academic Exceptions',
    subtitle: 'Any special course cases?',
    icon: Icons.tune_rounded,
  ),
  _StepMeta(
    title: 'Course Plan Review',
    subtitle: 'Fine-tune your custom plan',
    icon: Icons.checklist_rounded,
  ),
  _StepMeta(
    title: 'Final Review',
    subtitle: 'Confirm everything before finishing',
    icon: Icons.check_circle_rounded,
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

  List<int> _effectiveIndices(bool isRegular) =>
      isRegular ? [0, 1, 2, 3, 5] : [0, 1, 2, 3, 4, 5];

  Widget _buildStepWidget(int idx) => switch (idx) {
        0 => const identity_step.AcademicIdentityStep(),
        1 => const semester_step.SemesterProgressStep(),
        2 => const sgpa_step.SgpaHistoryStep(),
        3 => const exception_step.AcademicExceptionStep(),
        4 => const plan_review_step.CoursePlanReviewStep(),
        5 => const review_step.ReviewStep(),
        _ => const SizedBox.shrink(),
      };

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final authUser = ref.watch(authProvider).user;

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
    final meta = _kSteps[widgetIndex];
    final progress = (safeStep + 1) / totalSteps;

    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kBg, _kBgAlt],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              _WizardTopBar(
                canGoBack: safeStep > 0 && !_isFinishing,
                meta: meta,
                currentStep: safeStep,
                totalSteps: totalSteps,
                onBack: () => setState(() => currentStep = safeStep - 1),
              ),

              const SizedBox(height: 14),

              // ── Progress bar + dots ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ProgressSection(
                  progress: progress,
                  effectiveIndices: effectiveIndices,
                  currentStep: safeStep,
                ),
              ),

              const SizedBox(height: 16),

              // ── Step header (animates on step change) ─────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.10),
                      end: Offset.zero,
                    ).animate(
                        CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: _StepHeader(key: ValueKey(widgetIndex), meta: meta),
              ),

              const SizedBox(height: 12),

              // ── Step content card ─────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 360),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.97, end: 1.0).animate(
                          CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic),
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

              // ── Navigation row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _NavRow(
                  canGoBack: safeStep > 0 && !_isFinishing,
                  isLastStep: isLastStep,
                  isLoading: _isFinishing,
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
      ),
    );
  }

  // ── Business logic (unchanged) ───────────────────────────────────────────

  Future<void> _handleContinue({
    required int safeStep,
    required int widgetIndex,
    required bool isLastStep,
  }) async {
    final data = ref.read(registrationProvider);

    if (safeStep == 0) {
      if (data.department.isEmpty ||
          data.completedSemester == 0 ||
          data.studentId.isEmpty) {
        _showSnack(
            'Please complete your Student ID, department, and current semester');
        return;
      }
    }

    if (widgetIndex == 2) {
      final ok = ref
          .read(registrationProvider.notifier)
          .hasCompleteSemesterResults();
      if (!ok) {
        _showSnack('Please enter SGPA for all completed semesters');
        return;
      }
    }

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

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.info_outline_rounded, color: _kTxtPri, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: GoogleFonts.inter(color: _kTxtPri, fontSize: 13)),
          ),
        ]),
        backgroundColor: _kSurface2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _kBorder)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _WizardTopBar extends StatelessWidget {
  final bool canGoBack;
  final _StepMeta meta;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _WizardTopBar({
    required this.canGoBack,
    required this.meta,
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: canGoBack
                ? IconButton(
                    key: const ValueKey('back'),
                    onPressed: onBack,
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: _kTxtSec,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('spacer'), width: 48),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DIU CGPA Tracker',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: _kTxtDis, letterSpacing: 0.4)),
              Text('Academic Setup',
                  style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: _kTxtPri,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.28)),
            ),
            child: Text(
              '${currentStep + 1} of $totalSteps',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: _kPrimary,
                  fontWeight: FontWeight.w700),
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

  const _ProgressSection({
    required this.progress,
    required this.effectiveIndices,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(children: [
            Container(height: 4, color: Colors.white.withValues(alpha: 0.08)),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 4,
                  color: _kPrimary,
                ),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 10),

        // Step dots — single accent color
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: effectiveIndices.asMap().entries.map((e) {
            final i = e.key;
            final isCurrent = i == currentStep;
            final isPast = i < currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: isCurrent
                    ? _kPrimary
                    : isPast
                        ? _kPrimary.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step header
// ─────────────────────────────────────────────────────────────────────────────

class _StepHeader extends StatelessWidget {
  final _StepMeta meta;
  const _StepHeader({super.key, required this.meta});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _kPrimary.withValues(alpha: 0.28)),
            ),
            child: Icon(meta.icon, color: _kPrimary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kTxtPri,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  meta.subtitle,
                  style: GoogleFonts.inter(fontSize: 12, color: _kTxtSec),
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
// Step card — dark elevated surface with Theme override for inner widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final Widget child;
  const _StepCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _kSurface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Theme(
            data: _buildDarkTheme(),
            child: DefaultTextStyle(
              style: GoogleFonts.inter(color: _kTxtPri, fontSize: 14),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      canvasColor: _kSurface2,
      scaffoldBackgroundColor: _kSurface1,
      colorScheme: ColorScheme.dark(
        primary: _kPrimary,
        surface: _kSurface3,
        onSurface: _kTxtPri,
        onSurfaceVariant: _kTxtSec,
        outline: Colors.white.withValues(alpha: 0.14),
        error: _kError,
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        bodyMedium: TextStyle(color: _kTxtSec, fontSize: 14),
        bodyLarge:
            TextStyle(color: _kTxtPri, fontSize: 16, fontWeight: FontWeight.w600),
        bodySmall: TextStyle(color: _kTxtSec, fontSize: 12),
        headlineMedium:
            TextStyle(color: _kTxtPri, fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium:
            TextStyle(color: _kTxtPri, fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge:
            TextStyle(color: _kTxtPri, fontSize: 18, fontWeight: FontWeight.w700),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _kSurface3,
        labelStyle: const TextStyle(color: _kTxtSec, fontSize: 14),
        hintStyle: const TextStyle(color: _kTxtDis, fontSize: 14),
        prefixIconColor: _kTxtSec,
        suffixIconColor: _kTxtSec,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _kError),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _kError, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        isDense: true,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: _kTxtSec,
        textColor: _kTxtPri,
        subtitleTextStyle: TextStyle(color: _kTxtSec, fontSize: 13),
      ),
      dividerColor: Colors.white12,
      dividerTheme: const DividerThemeData(color: Colors.white12),
      iconTheme: const IconThemeData(color: _kTxtSec),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStatePropertyAll(_kPrimary),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(_kPrimary),
        trackColor: WidgetStatePropertyAll(_kPrimary.withValues(alpha: 0.35)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _kSurface2,
        labelStyle: const TextStyle(color: _kTxtPri),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      cardColor: _kSurface2,
      cardTheme: CardThemeData(
        color: _kSurface2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation row
// ─────────────────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final bool canGoBack;
  final bool isLastStep;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _NavRow({
    required this.canGoBack,
    required this.isLastStep,
    required this.isLoading,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (canGoBack) ...[
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded,
                      color: _kTxtSec, size: 17),
                  const SizedBox(width: 6),
                  Text('Back',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _kTxtSec,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: GestureDetector(
            onTap: isLoading ? null : onContinue,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isLoading
                    ? _kPrimary.withValues(alpha: 0.50)
                    : _kPrimary,
                boxShadow: isLoading
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x336C63FF),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLastStep ? 'Complete Setup' : 'Continue',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Icon(
                            isLastStep
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.15, end: 0);
  }
}

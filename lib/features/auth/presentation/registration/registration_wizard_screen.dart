import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../academic/repository/student_repository.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../academic_exception/providers/academic_exception_provider.dart';

import '../../../cgpa/repository/cgpa_repository.dart';
import '../../../cgpa/providers/cgpa_provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../shared/widgets/primary_button.dart';

import '../../providers/registration_provider.dart';
import '../../providers/auth_provider.dart';

import 'widgets/academic_identity_step.dart' as identity_step;
import 'widgets/semester_progress_step.dart' as semester_step;
import 'widgets/sgpa_history_step.dart' as sgpa_step;
import 'widgets/academic_exception_step.dart' as exception_step;
import 'widgets/course_plan_review_step.dart' as plan_review_step;
import 'widgets/review_step.dart' as review_step;

class RegistrationWizardScreen extends ConsumerStatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  ConsumerState<RegistrationWizardScreen> createState() =>
      _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState
    extends ConsumerState<RegistrationWizardScreen> {
  // currentStep is the position inside effectiveIndices — NOT a raw widget index.
  int currentStep = 0;

  // All 6 widget titles in order (widget index 0..5).
  static const List<String> _allTitles = [
    'Academic Identity',   // widget 0
    'Semester Progress',   // widget 1
    'SGPA History',        // widget 2
    'Academic Exceptions', // widget 3
    'Course Plan Review',  // widget 4 — irregular only
    'Review',              // widget 5
  ];

  /// Returns the sequence of widget indices to show for this student type.
  /// Regular students skip index 4 (Course Plan Review).
  List<int> _effectiveIndices(bool isRegular) =>
      isRegular ? [0, 1, 2, 3, 5] : [0, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final effectiveIndices = _effectiveIndices(regState.isRegular);
    final totalSteps = effectiveIndices.length;

    // Clamp currentStep if student type changed and step list shrank
    final safeStep = currentStep.clamp(0, totalSteps - 1);
    if (safeStep != currentStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => currentStep = safeStep);
      });
    }

    final widgetIndex = effectiveIndices[safeStep];
    final isLastStep = safeStep == totalSteps - 1;
    final stepTitle = _allTitles[widgetIndex];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: safeStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary),
                onPressed: () {
                  if (safeStep > 0) {
                    setState(() => currentStep = safeStep - 1);
                  }
                },
              )
            : null,
        title: Text(
          stepTitle,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress Row ──────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Step ${safeStep + 1} of $totalSteps',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (safeStep + 1) / totalSteps,
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(stepTitle, style: AppTextStyles.headingMedium),
            const SizedBox(height: AppSpacing.md),

            // ── Step Content ──────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: widgetIndex,
                children: const [
                  identity_step.AcademicIdentityStep(),    // 0
                  semester_step.SemesterProgressStep(),    // 1
                  sgpa_step.SgpaHistoryStep(),              // 2
                  exception_step.AcademicExceptionStep(),  // 3
                  plan_review_step.CoursePlanReviewStep(), // 4
                  review_step.ReviewStep(),                // 5
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Navigation Buttons ────────────────────────────────────
            Row(
              children: [
                if (safeStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => currentStep = safeStep - 1),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: PrimaryButton(
                    text: isLastStep ? 'Finish' : 'Continue',
                    onPressed: () async {
                      final data = ref.read(registrationProvider);

                      // ── Step 0: Academic Identity validation ─────────
                      if (safeStep == 0) {
                        if (data.department.isEmpty ||
                            data.admissionTerm.isEmpty ||
                            data.completedSemester == 0 ||
                            data.studentId.isEmpty) {
                          _showSnack(
                              'Please complete academic information including Student ID');
                          return;
                        }
                      }

                      // ── Step 2: SGPA completeness check ──────────────
                      if (widgetIndex == 2) {
                        final isComplete = ref
                            .read(registrationProvider.notifier)
                            .hasCompleteSemesterResults();
                        if (!isComplete) {
                          _showSnack(
                              'Please enter all semester SGPA and select a supported intake');
                          return;
                        }
                      }

                      // ── Finish ────────────────────────────────────────
                      if (isLastStep) {
                        final repo = StudentRepository();
                        final cgpaRepo = CgpaRepository();

                        debugPrint('Saving Results: ${data.results}');

                        await ref
                            .read(registrationProvider.notifier)
                            .finishRegistration();

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
                        // Signal profile completion — RouterNotifier will
                        // redirect to /dashboard automatically.
                        await ref
                            .read(authProvider.notifier)
                            .markProfileComplete(
                              studentId: data.studentId,
                              department: data.department,
                            );
                      } else {
                        setState(() => currentStep = safeStep + 1);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

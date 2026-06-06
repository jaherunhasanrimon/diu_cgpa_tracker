import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../academic/repository/student_repository.dart';

import '../../../cgpa/repository/cgpa_repository.dart';
import '../../../cgpa/providers/cgpa_provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../shared/widgets/primary_button.dart';

import '../../providers/registration_provider.dart';

import 'widgets/academic_identity_step.dart' as identity_step;

import 'widgets/semester_progress_step.dart' as semester_step;

import 'widgets/sgpa_history_step.dart' as sgpa_step;

import 'widgets/academic_exception_step.dart' as exception_step;

import 'widgets/review_step.dart' as review_step;

class RegistrationWizardScreen extends ConsumerStatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  ConsumerState<RegistrationWizardScreen> createState() =>
      _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState
    extends ConsumerState<RegistrationWizardScreen> {
  int currentStep = 0;

  final List<String> stepTitles = [
    'Academic Identity',

    'Semester Progress',

    'SGPA History',

    'Academic Exceptions',

    'Review',
  ];

  void previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(stepTitles[currentStep])),

      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            LinearProgressIndicator(
              value: (currentStep + 1) / stepTitles.length,
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Step ${currentStep + 1} of ${stepTitles.length}',

              style: AppTextStyles.bodyMedium,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(stepTitles[currentStep], style: AppTextStyles.headingMedium),

            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: IndexedStack(
                index: currentStep,

                children: const [
                  identity_step.AcademicIdentityStep(),

                  semester_step.SemesterProgressStep(),

                  sgpa_step.SgpaHistoryStep(),

                  exception_step.AcademicExceptionStep(),

                  review_step.ReviewStep(),
                ],
              ),
            ),

            Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: previousStep,

                      child: const Text('Back'),
                    ),
                  ),

                if (currentStep > 0) const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: PrimaryButton(
                    text: currentStep == stepTitles.length - 1
                        ? 'Finish'
                        : 'Continue',

                    onPressed: () async {
                      final data = ref.read(registrationProvider);

                      // STEP 1 CHECK
                      if (currentStep == 0) {
                        if (data.department.isEmpty ||
                            data.admissionTerm.isEmpty ||
                            data.completedSemester == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please complete academic information',
                              ),
                            ),
                          );

                          return;
                        }
                      }

                      // SGPA CHECK
                      if (currentStep == 2) {
                        final isComplete = ref
                            .read(registrationProvider.notifier)
                            .hasCompleteSemesterResults();

                        if (!isComplete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please enter all semester SGPA and select a supported intake',
                              ),
                            ),
                          );

                          return;
                        }
                      }

                      // FINISH
                      if (currentStep == stepTitles.length - 1) {
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
                        );

                        ref.invalidate(cgpaProvider);
                        ref.invalidate(cgpaSummaryProvider);
                        ref.invalidate(semesterResultsProvider);

                        if (!context.mounted) {
                          return;
                        }

                        context.go('/dashboard');
                      } else {
                        setState(() {
                          currentStep++;
                        });
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
}

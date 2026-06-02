import 'package:flutter/material.dart';
import '../../../academic/repository/student_repository.dart';
import 'package:go_router/go_router.dart';
import 'widgets/academic_identity_step.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';

class RegistrationWizardScreen extends StatefulWidget {
  const RegistrationWizardScreen({super.key});

  @override
  State<RegistrationWizardScreen> createState() =>
      _RegistrationWizardScreenState();
}

class _RegistrationWizardScreenState
    extends State<RegistrationWizardScreen> {

  int currentStep = 0;

  final List<String> stepTitles = [
    'Academic Identity',
    'Semester Progress',
    'SGPA History',
    'Academic Exceptions',
    'Review',
  ];

  void nextStep() {

    if (currentStep < stepTitles.length - 1) {

      setState(() {
        currentStep++;
      });

    }
  }

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

      appBar: AppBar(
        title: Text(
          stepTitles[currentStep],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),

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

            Text(
              stepTitles[currentStep],
              style: AppTextStyles.headingMedium,
            ),

            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: IndexedStack(
                index: currentStep,

                children: const [

                  AcademicIdentityStep(),

                  Center(child: Text('Semester Progress Step')),

                  Center(child: Text('SGPA History Step')),

                  Center(child: Text('Academic Exception Step')),

                  Center(child: Text('Review Step')),
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

                if (currentStep > 0)
                  const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: PrimaryButton(
                    text: currentStep == stepTitles.length - 1
                        ? 'Finish'
                        : 'Continue',

                    onPressed: () async {

                      if (currentStep == stepTitles.length - 1) {

                        final repo = StudentRepository();


                        await repo.saveStudent(

                          department: 'CSE',

                          intake: 'Spring 2025',

                          semester: 1,

                        );


                        if (!mounted) return;


                        context.go(
                          '/dashboard',
                        );

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
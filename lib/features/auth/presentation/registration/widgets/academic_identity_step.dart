import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../academic/domain/curriculum_engine.dart';
import '../../../providers/registration_provider.dart';

class AcademicIdentityStep extends ConsumerStatefulWidget {
  const AcademicIdentityStep({super.key});

  @override
  ConsumerState<AcademicIdentityStep> createState() =>
      _AcademicIdentityStepState();
}

class _AcademicIdentityStepState extends ConsumerState<AcademicIdentityStep> {
  late final TextEditingController _studentIdController;

  /// The intake that was last auto-detected from the student ID.
  String? _autoDetectedIntake;

  @override
  void initState() {
    super.initState();
    final initialId = ref.read(registrationProvider).studentId;
    _studentIdController = TextEditingController(text: initialId);

    // Seed auto-detection from any previously saved ID.
    if (initialId.isNotEmpty) {
      _autoDetectedIntake = CurriculumEngine.studentIdToIntake(initialId);
    }
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  void _onStudentIdChanged(String value) {
    final notifier = ref.read(registrationProvider.notifier);
    final data = ref.read(registrationProvider);

    notifier.setStudentId(value.trim());

    final detected = CurriculumEngine.studentIdToIntake(value);

    // Silently auto-fill the admissionTerm in the provider so the rest
    // of the wizard (curriculum plan, SGPA step) still works correctly.
    if (detected != null && detected != data.admissionTerm) {
      notifier.setAcademicInfo(
        department: data.department,
        admissionTerm: detected,
        completedSemester: data.completedSemester,
      );
    }

    if (detected != _autoDetectedIntake) {
      setState(() => _autoDetectedIntake = detected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your academic structure.',
            style: AppTextStyles.bodyMedium,
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Student ID ────────────────────────────────────────────────────
          TextFormField(
            controller: _studentIdController,
            decoration: InputDecoration(
              labelText: 'Student ID',
              border: const OutlineInputBorder(),
              hintText: 'e.g. 241-15-12345',
              helperText: _autoDetectedIntake != null
                  ? 'Intake detected: $_autoDetectedIntake'
                  : 'Enter your ID — intake will be detected automatically',
              helperStyle: TextStyle(
                fontSize: 11,
                color: _autoDetectedIntake != null
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
                fontWeight: _autoDetectedIntake != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              suffixIcon: _autoDetectedIntake != null
                  ? Tooltip(
                      message: 'Intake auto-detected',
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            onChanged: _onStudentIdChanged,
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Department ────────────────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: data.department.isEmpty ? null : data.department,

            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),

            items: const [
              DropdownMenuItem(
                value: 'Computer Science & Engineering',
                child: Text('Computer Science & Engineering'),
              ),
            ],

            onChanged: (value) {
              if (value == null) return;
              notifier.setAcademicInfo(
                department: value,
                admissionTerm: data.admissionTerm,
                completedSemester: data.completedSemester,
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Current Semester ──────────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: data.completedSemester == 0
                ? null
                : data.completedSemester.toString(),

            decoration: const InputDecoration(
              labelText: 'Current Semester',
              border: OutlineInputBorder(),
            ),

            items: List.generate(
              12,
              (index) => DropdownMenuItem(
                value: '${index + 1}',
                child: Text('Semester ${index + 1}'),
              ),
            ),

            onChanged: (value) {
              if (value == null) return;
              final newSem = int.tryParse(value) ?? data.completedSemester;
              if (newSem != data.completedSemester) {
                notifier.setCompletedSemester(newSem);
              }
            },
          ),
        ],
      ),
    );
  }
}

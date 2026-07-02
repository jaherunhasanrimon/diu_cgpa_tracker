import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../academic/domain/curriculum_engine.dart';
import '../../../providers/registration_provider.dart';

// ── Onboarding design tokens (mirrored from wizard screen) ───────────────────
const _kSurface2 = Color(0xFF161D2E);
const _kPrimary  = Color(0xFF6C63FF);
const _kTxtPri   = Color(0xFFF8FAFC);
const _kTxtSec   = Color(0xFF94A3B8);
const _kTxtDis   = Color(0xFF64748B);
const _kSuccess  = Color(0xFF10B981);


class AcademicIdentityStep extends ConsumerStatefulWidget {
  const AcademicIdentityStep({super.key});

  @override
  ConsumerState<AcademicIdentityStep> createState() =>
      _AcademicIdentityStepState();
}

class _AcademicIdentityStepState extends ConsumerState<AcademicIdentityStep> {
  late final TextEditingController _studentIdController;
  String? _autoDetectedIntake;

  @override
  void initState() {
    super.initState();
    final initialId = ref.read(registrationProvider).studentId;
    _studentIdController = TextEditingController(text: initialId);
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about your academic structure.',
            style: GoogleFonts.inter(fontSize: 13, color: _kTxtSec, height: 1.5),
          ),

          const SizedBox(height: 20),

          // ── Student ID ─────────────────────────────────────────────────────
          TextFormField(
            controller: _studentIdController,
            style: GoogleFonts.inter(fontSize: 15, color: _kTxtPri),
            decoration: InputDecoration(
              labelText: 'Student ID',
              hintText: 'e.g. 241-15-12345',
              helperText: _autoDetectedIntake != null
                  ? 'Intake detected: $_autoDetectedIntake'
                  : 'Intake will be detected automatically',
              helperStyle: GoogleFonts.inter(
                fontSize: 11,
                color: _autoDetectedIntake != null ? _kSuccess : _kTxtDis,
                fontWeight: _autoDetectedIntake != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              prefixIcon: const Icon(Icons.badge_outlined, size: 18),
              suffixIcon: _autoDetectedIntake != null
                  ? Tooltip(
                      message: 'Intake auto-detected',
                      child: const Icon(Icons.auto_awesome_rounded,
                          size: 18, color: _kSuccess),
                    )
                  : null,
            ),
            onChanged: _onStudentIdChanged,
          ).animate(delay: 60.ms).fadeIn(duration: 320.ms),

          const SizedBox(height: 14),

          // ── Department ────────────────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: data.department.isEmpty ? null : data.department,

            decoration: const InputDecoration(
              labelText: 'Department',
              prefixIcon: Icon(Icons.apartment_rounded, size: 18),
            ),
            dropdownColor: _kSurface2,
            style: GoogleFonts.inter(fontSize: 15, color: _kTxtPri),
            iconEnabledColor: _kTxtDis,
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
          ).animate(delay: 110.ms).fadeIn(duration: 320.ms),

          const SizedBox(height: 14),

          // ── Current Semester ──────────────────────────────────────────────
          DropdownButtonFormField<String>(
            initialValue: data.completedSemester == 0
                ? null
                : data.completedSemester.toString(),

            decoration: const InputDecoration(
              labelText: 'Current Semester',
              prefixIcon: Icon(Icons.layers_rounded, size: 18),
            ),
            dropdownColor: _kSurface2,
            style: GoogleFonts.inter(fontSize: 15, color: _kTxtPri),
            iconEnabledColor: _kTxtDis,
            items: List.generate(
              12,
              (i) => DropdownMenuItem(
                value: '${i + 1}',
                child: Text('Semester ${i + 1}'),
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              final s = int.tryParse(value) ?? data.completedSemester;
              if (s != data.completedSemester) {
                notifier.setCompletedSemester(s);
              }
            },
          ).animate(delay: 160.ms).fadeIn(duration: 320.ms),
        ],
      ),
    );
  }
}

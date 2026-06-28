import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../academic/data/sources/cse_curriculum_source.dart';
import '../../../academic/data/models/course_model.dart';
import '../../../academic/domain/semester_tracker.dart';
import '../../../academic/repository/student_repository.dart';
import '../../../academic/providers/academic_provider.dart';
import '../../../academic_exception/data/models/academic_exception_model.dart';
import '../../../academic_exception/providers/academic_exception_provider.dart';
import '../../../cgpa/data/models/semester_result_model.dart';
import '../../../cgpa/providers/cgpa_provider.dart';
import '../../../cgpa/repository/cgpa_repository.dart';

class SemesterTransitionDialog extends ConsumerStatefulWidget {
  final int currentCompletedSemester;
  final String intake;

  const SemesterTransitionDialog({
    super.key,
    required this.currentCompletedSemester,
    required this.intake,
  });

  @override
  ConsumerState<SemesterTransitionDialog> createState() => _SemesterTransitionDialogState();
}

class _SemesterTransitionDialogState extends ConsumerState<SemesterTransitionDialog> {
  int _currentStep = 0; // 0: Input Grades, 1: Customize Next Plan

  // Step 1 State: Course wise grades
  late final List<CourseModel> _runningCourses;
  final Map<String, String> _selectedGrades = {}; // courseCode -> letterGrade
  final TextEditingController _sgpaController = TextEditingController();
  double _calculatedSgpa = 0.0;
  double _totalCredits = 0.0;

  // Step 2 State: Next Semester customization
  late final int _nextSemester;
  late final List<CourseModel> _nextRegularCourses;
  final List<AcademicExceptionModel> _retakeBacklogs = [];
  final Set<String> _selectedNextCourses = {}; // courseCodes to keep

  @override
  void initState() {
    super.initState();
    final runningSemester = widget.currentCompletedSemester + 1;
    _nextSemester = runningSemester + 1;

    // Load running semester courses
    _runningCourses = CseCurriculumSource.getCoursesForSemester(
      intake: widget.intake,
      semesterNumber: runningSemester,
    );

    // Initialize all running courses with A (3.75) by default
    for (final course in _runningCourses) {
      _selectedGrades[course.code] = 'A';
    }
    _recalculateSgpa();

    // Load next semester regular courses
    _nextRegularCourses = CseCurriculumSource.getCoursesForSemester(
      intake: widget.intake,
      semesterNumber: _nextSemester,
    );
    for (final course in _nextRegularCourses) {
      _selectedNextCourses.add(course.code);
    }

    // Load existing backlog exceptions
    final existingExceptions = ref.read(academicExceptionsProvider);
    for (final ex in existingExceptions) {
      if (!ex.completed) {
        _retakeBacklogs.add(ex);
        // By default, if scheduled for next semester, keep checked
        if (ex.completedSemester == null || ex.completedSemester == _nextSemester) {
          _selectedNextCourses.add(ex.courseId);
        }
      }
    }
  }

  @override
  void dispose() {
    _sgpaController.dispose();
    super.dispose();
  }

  void _recalculateSgpa() {
    double totalQualityPoints = 0.0;
    double totalCredits = 0.0;

    for (final course in _runningCourses) {
      final grade = _selectedGrades[course.code] ?? 'A';
      final gpa = SemesterTracker.letterGradeToGpaMap[grade] ?? 0.0;
      totalQualityPoints += (gpa * course.credit);
      totalCredits += course.credit;
    }

    _totalCredits = totalCredits;
    _calculatedSgpa = totalCredits == 0 ? 0.0 : totalQualityPoints / totalCredits;
    _sgpaController.text = _calculatedSgpa.toStringAsFixed(2);
  }

  Future<void> _submitTransition() async {
    final runningSemester = widget.currentCompletedSemester + 1;
    final finalSgpa = double.tryParse(_sgpaController.text) ?? _calculatedSgpa;

    // 1. Save course wise grades to Hive
    final existingGpaRecords = SemesterTracker.getCourseGpaRecords();
    for (final course in _runningCourses) {
      final grade = _selectedGrades[course.code] ?? 'A';
      final gpa = SemesterTracker.letterGradeToGpaMap[grade] ?? 0.0;
      final isRetake = grade == 'F (Retake)';

      existingGpaRecords[course.code] = {
        'gpa': gpa,
        'semester': runningSemester,
        'isRetake': isRetake,
      };
    }
    await SemesterTracker.saveCourseGpaRecords(existingGpaRecords);

    // 2. Add exceptions for any failed courses in the completed semester
    final exceptionsNotifier = ref.read(academicExceptionsProvider.notifier);
    
    // Clear old exceptions for the completed running semester to avoid duplication
    final oldExceptions = ref.read(academicExceptionsProvider);
    for (final ex in oldExceptions) {
      if (ex.originalSemester == runningSemester) {
        await exceptionsNotifier.removeException(ex.courseId);
      }
    }

    for (final course in _runningCourses) {
      final grade = _selectedGrades[course.code] ?? 'A';
      if (grade == 'F (Retake)') {
        await exceptionsNotifier.addException(
          AcademicExceptionModel(
            courseId: course.code,
            courseName: course.title,
            credit: course.credit,
            originalSemester: runningSemester,
            type: 'FAILED',
            completed: false,
            overridePrerequisite: false,
          ),
        );
      }
    }

    // 3. Save customization for next semester plan (Step 2)
    // - Next regular courses that are unchecked are saved as "DROPPED" exceptions for _nextSemester
    for (final course in _nextRegularCourses) {
      final isSelected = _selectedNextCourses.contains(course.code);
      if (!isSelected) {
        await exceptionsNotifier.addException(
          AcademicExceptionModel(
            courseId: course.code,
            courseName: course.title,
            credit: course.credit,
            originalSemester: _nextSemester,
            type: 'DROPPED',
            completed: false,
            overridePrerequisite: false,
          ),
        );
      } else {
        // Remove dropped exception if they decided to take it
        await exceptionsNotifier.removeException(course.code);
      }
    }

    // - For retakes/backlogs, if unchecked, schedule for next + 1 semester (defer)
    for (final backlog in _retakeBacklogs) {
      final isSelected = _selectedNextCourses.contains(backlog.courseId);
      final updatedBacklog = backlog.copyWith(
        completedSemester: isSelected ? _nextSemester : _nextSemester + 1,
      );
      await exceptionsNotifier.toggleOverride(
        courseId: updatedBacklog.courseId,
        courseName: updatedBacklog.courseName,
        credit: updatedBacklog.credit,
        originalSemester: updatedBacklog.originalSemester,
      );
      // Ensure exceptions state is updated properly
      await exceptionsNotifier.removeException(backlog.courseId);
      await exceptionsNotifier.addException(updatedBacklog);
    }

    // 4. Save results for runningSemester
    final cgpaRepo = CgpaRepository();
    final results = cgpaRepo.getResults();
    
    // Remove if duplicate exists
    results.removeWhere((r) => r.semester == runningSemester);
    results.add(
      SemesterResultModel(
        semester: runningSemester,
        sgpa: finalSgpa.clamp(0.0, 4.0),
        credit: _totalCredits,
      ),
    );
    results.sort((a, b) => a.semester.compareTo(b.semester));
    await cgpaRepo.save(results);

    // 5. Update completed semester count in student profile
    final studentRepo = StudentRepository();
    final student = studentRepo.getStudent() ?? {};
    final currentTerm = SemesterTracker.getTermAndYearForDate(DateTime.now());
    
    await studentRepo.saveStudent(
      department: student['department']?.toString() ?? 'Computer Science & Engineering',
      intake: student['intake']?.toString() ?? 'Tri',
      semester: runningSemester,
      isRegular: student['isRegular'] as bool? ?? true,
      lastTrackedTerm: '${SemesterTracker.getTermName(currentTerm.$1)} ${currentTerm.$2}',
    );

    // 6. Refresh / invalidate providers
    ref.invalidate(studentProvider);
    ref.invalidate(semesterResultsProvider);
    ref.invalidate(cgpaSummaryProvider);
    ref.invalidate(academicExceptionsProvider);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully transitioned to Semester ${runningSemester + 1}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final runningSemester = widget.currentCompletedSemester + 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 680),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Title & step indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentStep == 0
                      ? 'Complete Semester $runningSemester'
                      : 'Customize Plan',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of 2',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_currentStep + 1) / 2,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Step Content
            Expanded(
              child: _currentStep == 0 ? _buildGradesStep() : _buildPlanStep(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Navigation Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentStep > 0) ...[
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (_currentStep == 0) {
                      // If any courses are failed, move to Step 2 (customization). Otherwise, skip to transition!
                      final hasFailures = _selectedGrades.values.any((grade) => grade == 'F (Retake)');
                      if (hasFailures || _retakeBacklogs.isNotEmpty) {
                        setState(() => _currentStep = 1);
                      } else {
                        _submitTransition();
                      }
                    } else {
                      _submitTransition();
                    }
                  },
                  child: Text(_currentStep == 0
                      ? (_selectedGrades.values.any((g) => g == 'F (Retake)') || _retakeBacklogs.isNotEmpty
                          ? 'Next'
                          : 'Confirm & Transition')
                      : 'Confirm & Transition'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradesStep() {
    final runningSemester = widget.currentCompletedSemester + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Input the grades you received for each course in Semester $runningSemester. Failing a course marks it as a retake.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),

        // Course List
        Expanded(
          child: _runningCourses.isEmpty
              ? const Center(
                  child: Text('No courses mapped in the curriculum for this semester.'),
                )
              : ListView.separated(
                  itemCount: _runningCourses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final course = _runningCourses[index];
                    final selectedGrade = _selectedGrades[course.code] ?? 'A';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${course.code}: ${course.title}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${course.credit.toStringAsFixed(1)} Credits',
                                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          DropdownButton<String>(
                            value: selectedGrade,
                            underline: const SizedBox(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: selectedGrade == 'F (Retake)' ? AppColors.danger : AppColors.success,
                            ),
                            items: SemesterTracker.letterGradeToGpaMap.keys
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedGrades[course.code] = value;
                                _recalculateSgpa();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: AppSpacing.md),

        // SGPA Summary row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculated SGPA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _calculatedSgpa.toStringAsFixed(2),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 120,
              child: TextFormField(
                controller: _sgpaController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Override SGPA',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanStep() {
    final nextSemester = widget.currentCompletedSemester + 2;

    // Separate next semester regular courses and failed retakes
    final newRetakes = _runningCourses
        .where((c) => _selectedGrades[c.code] == 'F (Retake)')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize your curriculum plan for Semester $nextSemester. Choose which courses to register for.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),

        Expanded(
          child: ListView(
            children: [
              // 1. Newly Failed Courses (Must Retake)
              if (newRetakes.isNotEmpty) ...[
                _SectionTitle(title: 'New Retakes (From Semester ${nextSemester - 1})', color: AppColors.danger),
                ...newRetakes.map((course) {
                  final isChecked = _selectedNextCourses.contains(course.code);
                  return CheckboxListTile(
                    activeColor: AppColors.danger,
                    title: Text(
                      '${course.code}: ${course.title}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${course.credit} Credits · Retake Suggested'),
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedNextCourses.add(course.code);
                        } else {
                          _selectedNextCourses.remove(course.code);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],

              // 2. Existing Backlog/Retake Courses
              if (_retakeBacklogs.isNotEmpty) ...[
                _SectionTitle(title: 'Prior Backlog / Retakes', color: AppColors.warning),
                ..._retakeBacklogs.map((ex) {
                  final isChecked = _selectedNextCourses.contains(ex.courseId);
                  return CheckboxListTile(
                    activeColor: AppColors.warning,
                    title: Text(
                      '${ex.courseId}: ${ex.courseName}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${ex.credit} Credits · Original Sem: ${ex.originalSemester}'),
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedNextCourses.add(ex.courseId);
                        } else {
                          _selectedNextCourses.remove(ex.courseId);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.md),
              ],

              // 3. Regular Next Semester Courses
              _SectionTitle(title: 'Standard Semester $nextSemester Courses', color: AppColors.success),
              if (_nextRegularCourses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No standard curriculum courses mapped for this semester.'),
                )
              else
                ..._nextRegularCourses.map((course) {
                  final isChecked = _selectedNextCourses.contains(course.code);
                  return CheckboxListTile(
                    activeColor: AppColors.success,
                    title: Text(
                      '${course.code}: ${course.title}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${course.credit} Credits'),
                    value: isChecked,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedNextCourses.add(course.code);
                        } else {
                          _selectedNextCourses.remove(course.code);
                        }
                      });
                    },
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

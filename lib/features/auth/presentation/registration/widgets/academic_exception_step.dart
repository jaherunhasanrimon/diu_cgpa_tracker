import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../academic/data/sources/cse_courses_data.dart';
import '../../../../academic/data/models/course_model.dart';
import '../../../../academic_exception/data/models/academic_exception_model.dart';
import '../../../providers/registration_provider.dart';

class AcademicExceptionStep extends ConsumerWidget {
  const AcademicExceptionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationProvider);
    final notifier = ref.read(registrationProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you have any retake, improvement, dropped or incomplete courses?',
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ToggleButton(
                  title: 'No',
                  subtitle: 'Regular Student',
                  isSelected: state.isRegular,
                  icon: Icons.check_circle_outline,
                  onTap: () => notifier.setIsRegular(true),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ToggleButton(
                  title: 'Yes',
                  subtitle: 'Irregular Student',
                  isSelected: !state.isRegular,
                  icon: Icons.error_outline,
                  onTap: () => notifier.setIsRegular(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.isRegular)
            _RegularBanner()
          else
            _IrregularFormSection(
              exceptions: state.exceptions,
              completedSemester: state.completedSemester,
              onAdd: (exception) => notifier.addException(exception),
              onRemove: (id) => notifier.removeException(id),
            ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isSelected ? AppColors.primary : AppColors.border;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegularBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regular Academic Track',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Great! You will proceed on the standard program track. Credit counts and curriculum progress will match your intake structure perfectly.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: const Color(0xFF047857),
                    fontSize: 13,
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

class _IrregularFormSection extends StatelessWidget {
  final List<AcademicExceptionModel> exceptions;
  final int completedSemester;
  final ValueChanged<AcademicExceptionModel> onAdd;
  final ValueChanged<String> onRemove;

  const _IrregularFormSection({
    required this.exceptions,
    required this.completedSemester,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exceptions Record',
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => _showAddExceptionSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Exception'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (exceptions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_late_outlined,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 48,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No exceptions listed yet',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tap "+ Add Exception" to record your retake, improvement, or dropped courses.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: exceptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final exception = exceptions[index];
              return _ExceptionCard(
                exception: exception,
                onDelete: () => onRemove(exception.id),
              );
            },
          ),
      ],
    );
  }

  void _showAddExceptionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _AddExceptionForm(
          completedSemester: completedSemester,
          onSave: (exception) {
            onAdd(exception);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

class _ExceptionCard extends StatelessWidget {
  final AcademicExceptionModel exception;
  final VoidCallback onDelete;

  const _ExceptionCard({required this.exception, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    String typeLabel;

    switch (exception.type) {
      case 'retake':
        typeColor = AppColors.danger;
        typeLabel = 'Retake';
        break;
      case 'improvement':
        typeColor = AppColors.warning;
        typeLabel = 'Improvement';
        break;
      default:
        typeColor = AppColors.secondary;
        typeLabel = 'Dropped';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              typeLabel,
              style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${exception.courseCode}: ${exception.courseTitle}',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sem ${exception.semester} • ${exception.credit} Credits${_gradeSuffix()}',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  String _gradeSuffix() {
    if (exception.type == 'dropped') return '';
    final oldG = exception.oldGrade ?? '';
    final newG = exception.newGrade ?? 'Pending';
    return ' • Grade: $oldG → $newG';
  }
}

class _AddExceptionForm extends StatefulWidget {
  final int completedSemester;
  final ValueChanged<AcademicExceptionModel> onSave;

  const _AddExceptionForm({
    required this.completedSemester,
    required this.onSave,
  });

  @override
  State<_AddExceptionForm> createState() => _AddExceptionFormState();
}

class _AddExceptionFormState extends State<_AddExceptionForm> {
  String type = 'retake'; // 'retake', 'improvement', 'dropped'
  int selectedSemester = 1;
  CourseModel? selectedCourse;
  String? oldGrade;
  String? newGrade = 'Pending';

  final List<String> grades = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Academic Exception',
                style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(
              labelText: 'Exception Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'retake', child: Text('Retake Course')),
              DropdownMenuItem(value: 'improvement', child: Text('Improvement Course')),
              DropdownMenuItem(value: 'dropped', child: Text('Dropped / Incomplete Course')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                type = value;
                if (type == 'dropped') {
                  oldGrade = null;
                  newGrade = null;
                } else {
                  oldGrade = oldGrade ?? 'F';
                  newGrade = newGrade ?? 'Pending';
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            initialValue: selectedSemester,
            decoration: const InputDecoration(
              labelText: 'Semester Occurred',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              widget.completedSemester,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('Semester ${index + 1}'),
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                selectedSemester = value;
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<CourseModel>(
            initialValue: selectedCourse,
            decoration: const InputDecoration(
              labelText: 'Select Course',
              border: OutlineInputBorder(),
            ),
            items: CseCoursesData.courses
                .map(
                  (course) => DropdownMenuItem(
                    value: course,
                    child: Text('${course.code}: ${course.title} (${course.credit} credits)'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedCourse = value;
              });
            },
          ),
          if (type != 'dropped') ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: oldGrade ?? 'F',
                    decoration: const InputDecoration(
                      labelText: 'Original Grade',
                      border: OutlineInputBorder(),
                    ),
                    items: grades
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        oldGrade = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: newGrade ?? 'Pending',
                    decoration: const InputDecoration(
                      labelText: 'New/Expected Grade',
                      border: OutlineInputBorder(),
                    ),
                    items: [...grades, 'Pending']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        newGrade = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: selectedCourse == null
                  ? null
                  : () {
                      final exception = AcademicExceptionModel(
                        id: const Uuid().v4(),
                        type: type,
                        courseCode: selectedCourse!.code,
                        courseTitle: selectedCourse!.title,
                        credit: selectedCourse!.credit,
                        semester: selectedSemester,
                        oldGrade: oldGrade ?? (type == 'dropped' ? null : 'F'),
                        newGrade: newGrade,
                      );
                      widget.onSave(exception);
                    },
              child: const Text('Add Exception'),
            ),
          ),
        ],
      ),
    );
  }
}
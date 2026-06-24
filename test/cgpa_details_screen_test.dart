import 'package:diu_cgpa_tracker/core/theme/app_colors.dart';
import 'package:diu_cgpa_tracker/features/academic_exception/data/models/academic_exception_model.dart';
import 'package:diu_cgpa_tracker/features/academic_exception/providers/academic_exception_provider.dart';
import 'package:diu_cgpa_tracker/features/cgpa/data/models/semester_result_model.dart';
import 'package:diu_cgpa_tracker/features/cgpa/providers/cgpa_provider.dart';
import 'package:diu_cgpa_tracker/features/cgpa/presentation/cgpa_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAcademicExceptionsNotifier extends AcademicExceptionsNotifier {
  final List<AcademicExceptionModel> initialExceptions;

  MockAcademicExceptionsNotifier(this.initialExceptions);

  @override
  void load() {
    state = initialExceptions;
  }
}

void main() {
  testWidgets('Highlights failed course in red, and passed course remains normal', (WidgetTester tester) async {
    final exceptions = [
      const AcademicExceptionModel(
        courseId: 'ENG101',
        courseName: 'Basic Functional English and English Spoken',
        credit: 3.0,
        originalSemester: 1,
        type: 'FAILED',
        completed: false,
        overridePrerequisite: false,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentIntakeProvider.overrideWith((ref) => 'Tri'),
          semesterResultsProvider.overrideWith((ref) => const [
                SemesterResultModel(semester: 1, sgpa: 3.5, credit: 19.5),
              ]),
          academicExceptionsProvider.overrideWith((ref) {
            return MockAcademicExceptionsNotifier(exceptions);
          }),
        ],
        child: const MaterialApp(
          home: CgpaDetailsScreen(),
        ),
      ),
    );

    // Expand the first semester card
    final semesterCard = find.text('Semester 1');
    expect(semesterCard, findsOneWidget);
    await tester.tap(semesterCard);
    await tester.pumpAndSettle();

    // The course 'ENG101' should be visible
    final failedCourseCodeText = find.text('ENG101');
    expect(failedCourseCodeText, findsOneWidget);

    // Find the Text widget for 'ENG101' and verify color is AppColors.danger
    final Text failedTextWidget = tester.widget<Text>(failedCourseCodeText);
    expect(failedTextWidget.style?.color, AppColors.danger);

    // Course 'MAT101' should also be visible and have normal color
    final normalCourseCodeText = find.text('MAT101');
    expect(normalCourseCodeText, findsOneWidget);

    final Text normalTextWidget = tester.widget<Text>(normalCourseCodeText);
    expect(normalTextWidget.style?.color, AppColors.primary);
  });
}

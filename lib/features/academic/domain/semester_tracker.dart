import '../../academic/data/sources/cse_curriculum_source.dart';
import '../../academic/repository/student_repository.dart';
import '../../academic/data/models/course_model.dart';
import '../../academic_exception/data/models/academic_exception_model.dart';
import '../../academic_exception/providers/academic_exception_provider.dart';
import '../../cgpa/data/models/semester_result_model.dart';
import '../../cgpa/repository/cgpa_repository.dart';
import '../../../core/storage/hive_service.dart';

class SemesterTracker {
  static const String _gpaRecordsKey = 'course_gpa_records';

  // DIU Letter Grade to GPA mapping
  static const Map<String, double> letterGradeToGpaMap = {
    'A+': 4.00,
    'A': 3.75,
    'A-': 3.50,
    'B+': 3.25,
    'B': 3.00,
    'B-': 2.75,
    'C+': 2.50,
    'C': 2.25,
    'D': 2.00,
    'F (Retake)': 0.00,
  };

  /// Returns the corresponding letter grade for a given GPA
  static String getLetterGradeForGpa(double gpa) {
    if (gpa >= 4.0) return 'A+';
    if (gpa >= 3.75) return 'A';
    if (gpa >= 3.5) return 'A-';
    if (gpa >= 3.25) return 'B+';
    if (gpa >= 3.0) return 'B';
    if (gpa >= 2.75) return 'B-';
    if (gpa >= 2.5) return 'C+';
    if (gpa >= 2.25) return 'C';
    if (gpa >= 2.0) return 'D';
    return 'F (Retake)';
  }

  /// Retrieves all course GPA records from Hive.
  /// Map structure: courseCode -> { 'gpa': double, 'semester': int, 'isRetake': bool }
  static Map<String, Map<String, dynamic>> getCourseGpaRecords() {
    final raw = HiveService.box.get(_gpaRecordsKey, defaultValue: {});
    if (raw is! Map) return {};
    
    final Map<String, Map<String, dynamic>> result = {};
    raw.forEach((k, v) {
      if (v is Map) {
        result[k.toString()] = {
          'gpa': (v['gpa'] as num?)?.toDouble() ?? 0.0,
          'semester': (v['semester'] as num?)?.toInt() ?? 1,
          'isRetake': v['isRetake'] as bool? ?? false,
        };
      }
    });
    return result;
  }

  /// Saves course GPA records to Hive.
  static Future<void> saveCourseGpaRecords(Map<String, Map<String, dynamic>> records) async {
    await HiveService.box.put(_gpaRecordsKey, records);
  }

  /// Parse the student ID or intake to find start term index (0: Spring, 1: Summer, 2: Fall) and start year.
  static (int startTermIndex, int startYear) getStartTermAndYear({
    required String studentId,
    required String intake,
  }) {
    final trimmedId = studentId.trim();
    if (trimmedId.isNotEmpty) {
      final firstPart = trimmedId.split('-').first;
      if (firstPart.length == 3) {
        final code = int.tryParse(firstPart);
        if (code != null) {
          final yearPart = code ~/ 10;
          final semPart = code % 10;
          
          final startYear = 2000 + yearPart;
          
          int startTermIndex = 0;
          if (startYear == 2024) {
            startTermIndex = (semPart == 2) ? 2 : 0; // 242 was Fall
          } else {
            if (semPart == 2) startTermIndex = 1;      // Summer
            else if (semPart == 3) startTermIndex = 2; // Fall
          }
          return (startTermIndex, startYear);
        }
      }
    }

    // Fallback parsing from intake string
    final intakeLower = intake.toLowerCase();
    int startTermIndex = 0;
    int startYear = DateTime.now().year;

    final yearRegex = RegExp(r'\b(20\d{2})\b');
    final match = yearRegex.firstMatch(intake);
    if (match != null) {
      startYear = int.tryParse(match.group(1) ?? '') ?? startYear;
    }

    if (intakeLower.contains('spring')) {
      startTermIndex = 0;
    } else if (intakeLower.contains('summer')) {
      startTermIndex = 1;
    } else if (intakeLower.contains('fall')) {
      startTermIndex = 2;
    }

    return (startTermIndex, startYear);
  }

  /// Returns the term details for a specific date.
  static (int termIndex, int year) getTermAndYearForDate(DateTime date) {
    int termIndex = 0; // 0: Spring, 1: Summer, 2: Fall
    if (date.month >= 1 && date.month <= 4) {
      termIndex = 0;
    } else if (date.month >= 5 && date.month <= 8) {
      termIndex = 1;
    } else {
      termIndex = 2;
    }
    return (termIndex, date.year);
  }

  /// Returns string name for a term index.
  static String getTermName(int index) {
    switch (index) {
      case 0: return 'Spring';
      case 1: return 'Summer';
      case 2: return 'Fall';
      default: return 'Spring';
    }
  }

  /// Performs auto-progression checks when student is loaded.
  static Map checkAndTransition({
    required Map student,
    required String studentId,
    DateTime? mockNow,
  }) {
    final now = mockNow ?? DateTime.now();
    final intake = student['intake']?.toString() ?? 'Tri';
    final storedCompletedSemester = (student['semester'] as num?)?.toInt() ?? 0;
    final isRegular = student['isRegular'] as bool? ?? true;
    final department = student['department']?.toString() ?? 'Computer Science & Engineering';
    final lastTrackedTermStr = student['lastTrackedTerm']?.toString();

    final (currentTermIndex, currentYear) = getTermAndYearForDate(now);
    final currentTermName = getTermName(currentTermIndex);

    // If lastTrackedTerm is not stored yet, initialize it
    if (lastTrackedTermStr == null) {
      final studentRepo = StudentRepository();
      studentRepo.saveStudent(
        department: department,
        intake: intake,
        semester: storedCompletedSemester,
        isRegular: isRegular,
        lastTrackedTerm: '$currentTermName $currentYear',
      );
      
      return {
        'department': department,
        'intake': intake,
        'semester': storedCompletedSemester,
        'isRegular': isRegular,
        'lastTrackedTerm': '$currentTermName $currentYear',
      };
    }

    final parts = lastTrackedTermStr.split(' ');
    if (parts.length != 2) return student;
    final lastTermName = parts[0];
    final lastTermYear = int.tryParse(parts[1]) ?? now.year;
    
    int lastTermIndex = 0;
    if (lastTermName.toLowerCase().contains('spring')) lastTermIndex = 0;
    else if (lastTermName.toLowerCase().contains('summer')) lastTermIndex = 1;
    else if (lastTermName.toLowerCase().contains('fall')) lastTermIndex = 2;

    // Calculate semesters elapsed since last tracked term
    final yearDiff = currentYear - lastTermYear;
    final semestersElapsed = (yearDiff * 3) + (currentTermIndex - lastTermIndex);

    if (semestersElapsed > 0) {
      final newCompletedSemester = storedCompletedSemester + semestersElapsed;

      // Update student record
      final studentRepo = StudentRepository();
      studentRepo.saveStudent(
        department: department,
        intake: intake,
        semester: newCompletedSemester,
        isRegular: isRegular,
        lastTrackedTerm: '$currentTermName $currentYear',
      );

      // Populate placeholder semester results
      final cgpaRepo = CgpaRepository();
      final currentResults = cgpaRepo.getResults();
      
      final Map<int, SemesterResultModel> resultsMap = {
        for (final r in currentResults) r.semester: r
      };

      final curriculum = CseCurriculumSource.getSemesters(intake: intake);

      for (int sem = storedCompletedSemester + 1; sem <= newCompletedSemester; sem++) {
        if (!resultsMap.containsKey(sem)) {
          final index = sem - 1;
          final credit = index < curriculum.length ? curriculum[index].credit : 0.0;
          resultsMap[sem] = SemesterResultModel(
            semester: sem,
            sgpa: 0.0,
            credit: credit,
          );
        }
      }

      final updatedResults = resultsMap.values.toList()
        ..sort((a, b) => a.semester.compareTo(b.semester));

      cgpaRepo.save(updatedResults);

      return {
        'department': department,
        'intake': intake,
        'semester': newCompletedSemester,
        'isRegular': isRegular,
        'lastTrackedTerm': '$currentTermName $currentYear',
      };
    }

    return student;
  }

  /// Updates grades, recalculates SGPA, and creates/removes failure exceptions for a completed semester.
  static Future<void> updatePastSemesterGrades({
    required int semester,
    required String intake,
    required Map<String, String> courseGrades,
    required double enteredSgpa,
    required List<CourseModel> courses,
    required AcademicExceptionsNotifier exceptionsNotifier,
    required List<AcademicExceptionModel> existingExceptions,
  }) async {
    // 1. Update course GPA records
    final gpaRecords = getCourseGpaRecords();
    for (final course in courses) {
      final grade = courseGrades[course.code] ?? 'A';
      final gpa = letterGradeToGpaMap[grade] ?? 0.0;
      final isRetake = grade == 'F (Retake)';
      gpaRecords[course.code] = {
        'gpa': gpa,
        'semester': semester,
        'isRetake': isRetake,
      };
    }
    await saveCourseGpaRecords(gpaRecords);

    // 2. Update academic exceptions
    for (final course in courses) {
      final grade = courseGrades[course.code] ?? 'A';
      final hasFailedEx = existingExceptions.any((e) => e.courseId == course.code && e.originalSemester == semester);
      
      if (grade == 'F (Retake)') {
        if (!hasFailedEx) {
          await exceptionsNotifier.addException(
            AcademicExceptionModel(
              courseId: course.code,
              courseName: course.title,
              credit: course.credit,
              originalSemester: semester,
              type: 'FAILED',
              completed: false,
              overridePrerequisite: false,
            ),
          );
        }
      } else {
        if (hasFailedEx) {
          await exceptionsNotifier.removeException(course.code);
        }
      }
    }

    // 3. Update CgpaRepository results list
    final cgpaRepo = CgpaRepository();
    final results = cgpaRepo.getResults();
    final index = results.indexWhere((r) => r.semester == semester);
    
    double totalCredits = courses.fold(0.0, (sum, c) => sum + c.credit);
    
    if (index != -1) {
      results[index] = SemesterResultModel(
        semester: semester,
        sgpa: enteredSgpa.clamp(0.0, 4.0),
        credit: totalCredits,
      );
    } else {
      results.add(SemesterResultModel(
        semester: semester,
        sgpa: enteredSgpa.clamp(0.0, 4.0),
        credit: totalCredits,
      ));
    }
    results.sort((a, b) => a.semester.compareTo(b.semester));
    await cgpaRepo.save(results);
  }
}

import '../models/course_model.dart';

class CseCurriculumData {
  static const Map<String, List<List<CourseModel>>> courses = {
    "Spring 2024": [
      // Semester 1
      [
        CourseModel(code: 'ENG101', title: 'Basic Functional English and English Spoken', credit: 3.0),
        CourseModel(code: 'MAT101', title: 'Mathematics - I', credit: 3.0),
        CourseModel(code: 'PHY101', title: 'Physics-I', credit: 3.0),
        CourseModel(code: 'CSE112', title: 'Computer Fundamentals', credit: 3.0),
        CourseModel(code: 'CSE113', title: 'Programming and Problem Solving', credit: 3.0),
        CourseModel(code: 'CSE114', title: 'Programming and Problem Solving Lab', credit: 1.5),
        CourseModel(code: 'CSE115', title: 'Introduction to Biology and Chemistry for Computation', credit: 3.0),
      ],
      // Semester 2
      [
        CourseModel(code: 'ENG102', title: 'Writing and Comprehension', credit: 3.0, prerequisites: ['ENG101']),
        CourseModel(code: 'MAT102', title: 'Mathematics-II: Calculus, Complex Variables and Linear Algebra', credit: 3.0, prerequisites: ['MAT101']),
        CourseModel(code: 'PHY102', title: 'Physics - II', credit: 3.0, prerequisites: ['PHY101']),
        CourseModel(code: 'PHY103', title: 'Physics - II Lab', credit: 1.5, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE121', title: 'Electrical Circuits', credit: 3.0, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE122', title: 'Electrical Circuits Lab', credit: 1.5, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE123', title: 'Data Structure', credit: 3.0, prerequisites: ['CSE113']),
        CourseModel(code: 'CSE124', title: 'Data Structure Lab', credit: 1.5, prerequisites: ['CSE114']),
      ],
      // Semester 3
      [
        CourseModel(code: 'MAT211', title: 'Engineering Mathematics', credit: 3.0, prerequisites: ['MAT102']),
        CourseModel(code: 'CSE212', title: 'Discrete Mathematics', credit: 3.0),
        CourseModel(code: 'CSE213', title: 'Algorithms', credit: 3.0, prerequisites: ['CSE123']),
        CourseModel(code: 'CSE214', title: 'Algorithms Lab', credit: 1.5, prerequisites: ['CSE124']),
        CourseModel(code: 'BNS101', title: 'Bangladesh Studies (History of Independence and Contemporary Issues)', credit: 3.0),
      ],
      // Semester 4
      [
        CourseModel(code: 'AOL101', title: 'Art of Living', credit: 3.0),
        CourseModel(code: 'CSE221', title: 'Object Oriented Programming', credit: 3.0, prerequisites: ['CSE113', 'CSE213']),
        CourseModel(code: 'CSE222', title: 'Object Oriented Programming Lab', credit: 1.5, prerequisites: ['CSE114', 'CSE214']),
        CourseModel(code: 'CSE215', title: 'Electronic Devices and Circuits', credit: 3.0, prerequisites: ['CSE121']),
        CourseModel(code: 'CSE216', title: 'Electronic Devices and Circuits Lab', credit: 1.5, prerequisites: ['CSE122']),
      ],
      // Semester 5
      [
        CourseModel(code: 'CSE223', title: 'Digital Logic Design', credit: 3.0, prerequisites: ['CSE121', 'CSE215']),
        CourseModel(code: 'CSE224', title: 'Digital Logic Design Lab', credit: 1.5, prerequisites: ['CSE122', 'CSE216']),
        CourseModel(code: 'CSE225', title: 'Data Communication', credit: 3.0, prerequisites: ['CSE112']),
        CourseModel(code: 'CSE227', title: 'Systems Analysis and Design', credit: 3.0, prerequisites: ['CSE113', 'CSE212']),
        CourseModel(code: 'CSE228', title: 'Theory of Computation', credit: 3.0, prerequisites: ['CSE212']),
      ],
      // Semester 6
      [
        CourseModel(code: 'CSE226', title: 'Numerical Methods', credit: 3.0, prerequisites: ['MAT211']),
        CourseModel(code: 'CSE311', title: 'Database Management System', credit: 3.0, prerequisites: ['CSE221']),
        CourseModel(code: 'CSE312', title: 'Database Management System Lab', credit: 1.5, prerequisites: ['CSE222']),
        CourseModel(code: 'CSE313', title: 'Compiler Design', credit: 3.0, prerequisites: ['CSE228']),
        CourseModel(code: 'CSE314', title: 'Compiler Design Lab', credit: 1.5, prerequisites: ['CSE114']),
      ],
      // Semester 7
      [
        CourseModel(code: 'CSE315', title: 'Software Engineering', credit: 3.0, prerequisites: ['CSE227']),
        CourseModel(code: 'CSE317', title: 'Microprocessor and Microcontrollers', credit: 3.0, prerequisites: ['CSE223']),
        CourseModel(code: 'CSE321', title: 'Computer Networks', credit: 3.0, prerequisites: ['CSE225']),
        CourseModel(code: 'CSE322', title: 'Computer Networks Lab', credit: 1.5, prerequisites: ['CSE221']),
        CourseModel(code: 'ACT327', title: 'Financial and Managerial Accounting', credit: 3.0),
      ],
      // Semester 8
      [
        CourseModel(code: 'STA101', title: 'Statistics and Probability', credit: 3.0, prerequisites: ['MAT211']),
        CourseModel(code: 'CSE316', title: 'Artificial Intelligence', credit: 3.0),
        CourseModel(code: 'CSE323', title: 'Operating Systems', credit: 3.0, prerequisites: ['CSE221']),
        CourseModel(code: 'CSE324', title: 'Operating Systems Lab', credit: 1.5, prerequisites: ['CSE222']),
        CourseModel(code: 'CSE-EL1', title: 'Elective-I (specialization)', credit: 3.0),
      ],
      // Semester 9
      [
        CourseModel(code: 'CSE325', title: 'Instrumentation and Control', credit: 3.0, prerequisites: ['CSE215']),
        CourseModel(code: 'CSE326', title: 'Social and Professional Issues in Computing', credit: 3.0),
        CourseModel(code: 'CSE411', title: 'Computer Graphics', credit: 3.0, prerequisites: ['CSE113']),
        CourseModel(code: 'CSE412', title: 'Computer Graphics Lab', credit: 1.5, prerequisites: ['CSE114']),
        CourseModel(code: 'CSE-EL2', title: 'Elective-II (specialization)', credit: 3.0),
      ],
      // Semester 10
      [
        CourseModel(code: 'CSE413', title: 'Computer Architecture and Organization', credit: 3.0, prerequisites: ['CSE223']),
        CourseModel(code: 'CSE-EL3', title: 'Elective-III (specialization)', credit: 3.0),
        CourseModel(code: 'CSE-EL4', title: 'Elective-IV (specialization)', credit: 3.0),
        CourseModel(code: 'CSE498', title: 'Capstone Project Phase-I', credit: 3.0),
      ],
      // Semester 11
      [
        CourseModel(code: 'ECO426', title: 'Engineering Economics', credit: 3.0),
        CourseModel(code: 'CSE-EL5', title: 'Elective-V (specialization)', credit: 3.0),
        CourseModel(code: 'CSE-EL6', title: 'Elective-VI (specialization)', credit: 3.0),
        CourseModel(code: 'CSE499', title: 'Capstone Project Phase-II', credit: 3.0, prerequisites: ['CSE498']),
      ]
    ],
    "Fall 2024": [
      // Semester 1
      [
        CourseModel(code: 'ENG101', title: 'Basic Functional English and English Spoken', credit: 3.0),
        CourseModel(code: 'MAT101', title: 'Mathematics - I', credit: 3.0),
        CourseModel(code: 'PHY101', title: 'Physics-I', credit: 3.0),
        CourseModel(code: 'CSE112', title: 'Computer Fundamentals', credit: 3.0),
        CourseModel(code: 'CSE113', title: 'Programming and Problem Solving', credit: 3.0),
        CourseModel(code: 'CSE114', title: 'Programming and Problem Solving Lab', credit: 1.5),
        CourseModel(code: 'CSE115', title: 'Introduction to Biology and Chemistry for Computation', credit: 3.0),
      ],
      // Semester 2
      [
        CourseModel(code: 'ENG102', title: 'Writing and Comprehension', credit: 3.0, prerequisites: ['ENG101']),
        CourseModel(code: 'MAT102', title: 'Mathematics-II: Calculus, Complex Variables and Linear Algebra', credit: 3.0, prerequisites: ['MAT101']),
        CourseModel(code: 'PHY102', title: 'Physics - II', credit: 3.0, prerequisites: ['PHY101']),
        CourseModel(code: 'PHY103', title: 'Physics - II Lab', credit: 1.5, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE123', title: 'Data Structure', credit: 3.0, prerequisites: ['CSE113']),
        CourseModel(code: 'CSE124', title: 'Data Structure Lab', credit: 1.5, prerequisites: ['CSE114']),
      ],
      // Semester 3
      [
        CourseModel(code: 'MAT211', title: 'Engineering Mathematics', credit: 3.0, prerequisites: ['MAT102']),
        CourseModel(code: 'CSE212', title: 'Discrete Mathematics', credit: 3.0),
        CourseModel(code: 'CSE213', title: 'Algorithms', credit: 3.0, prerequisites: ['CSE123']),
        CourseModel(code: 'CSE214', title: 'Algorithms Lab', credit: 1.5, prerequisites: ['CSE124']),
        CourseModel(code: 'CSE121', title: 'Electrical Circuits', credit: 3.0, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE122', title: 'Electrical Circuits Lab', credit: 1.5, prerequisites: ['PHY101']),
      ],
      // Semester 4
      [
        CourseModel(code: 'AOL101', title: 'Art of Living', credit: 3.0),
        CourseModel(code: 'CSE221', title: 'Object Oriented Programming', credit: 3.0, prerequisites: ['CSE113', 'CSE213']),
        CourseModel(code: 'CSE222', title: 'Object Oriented Programming Lab', credit: 1.5, prerequisites: ['CSE114', 'CSE214']),
        CourseModel(code: 'CSE215', title: 'Electronic Devices and Circuits', credit: 3.0, prerequisites: ['CSE121']),
        CourseModel(code: 'CSE216', title: 'Electronic Devices and Circuits Lab', credit: 1.5, prerequisites: ['CSE122']),
        CourseModel(code: 'BNS101', title: 'Bangladesh Studies (History of Independence and Contemporary Issues)', credit: 3.0),
      ],
      // Semester 5
      [
        CourseModel(code: 'CSE223', title: 'Digital Logic Design', credit: 3.0, prerequisites: ['CSE121', 'CSE215']),
        CourseModel(code: 'CSE224', title: 'Digital Logic Design Lab', credit: 1.5, prerequisites: ['CSE122', 'CSE216']),
        CourseModel(code: 'CSE225', title: 'Data Communication', credit: 3.0, prerequisites: ['CSE112']),
        CourseModel(code: 'CSE227', title: 'Systems Analysis and Design', credit: 3.0, prerequisites: ['CSE113', 'CSE212']),
        CourseModel(code: 'CSE228', title: 'Theory of Computation', credit: 3.0, prerequisites: ['CSE212']),
      ],
      // Semester 6
      [
        CourseModel(code: 'CSE226', title: 'Numerical Methods', credit: 3.0, prerequisites: ['MAT211']),
        CourseModel(code: 'CSE311', title: 'Database Management System', credit: 3.0, prerequisites: ['CSE221']),
        CourseModel(code: 'CSE312', title: 'Database Management System Lab', credit: 1.5, prerequisites: ['CSE222']),
        CourseModel(code: 'CSE313', title: 'Compiler Design', credit: 3.0, prerequisites: ['CSE228']),
        CourseModel(code: 'CSE314', title: 'Compiler Design Lab', credit: 1.5, prerequisites: ['CSE114']),
      ],
      // Semester 7
      [
        CourseModel(code: 'CSE315', title: 'Software Engineering', credit: 3.0, prerequisites: ['CSE227']),
        CourseModel(code: 'CSE317', title: 'Microprocessor and Microcontrollers', credit: 3.0, prerequisites: ['CSE223']),
        CourseModel(code: 'CSE321', title: 'Computer Networks', credit: 3.0, prerequisites: ['CSE225']),
        CourseModel(code: 'CSE322', title: 'Computer Networks Lab', credit: 1.5, prerequisites: ['CSE221']),
        CourseModel(code: 'ACT327', title: 'Financial and Managerial Accounting', credit: 3.0),
      ],
      // Semester 8
      [
        CourseModel(code: 'STA101', title: 'Statistics and Probability', credit: 3.0, prerequisites: ['MAT211']),
        CourseModel(code: 'CSE316', title: 'Artificial Intelligence', credit: 3.0),
        CourseModel(code: 'CSE323', title: 'Operating Systems', credit: 3.0, prerequisites: ['CSE221']),
        CourseModel(code: 'CSE324', title: 'Operating Systems Lab', credit: 1.5, prerequisites: ['CSE222']),
        CourseModel(code: 'CSE-EL1', title: 'Elective-I (specialization)', credit: 3.0),
      ],
      // Semester 9
      [
        CourseModel(code: 'CSE325', title: 'Instrumentation and Control', credit: 3.0, prerequisites: ['CSE215']),
        CourseModel(code: 'CSE326', title: 'Social and Professional Issues in Computing', credit: 3.0),
        CourseModel(code: 'CSE411', title: 'Computer Graphics', credit: 3.0, prerequisites: ['CSE113']),
        CourseModel(code: 'CSE412', title: 'Computer Graphics Lab', credit: 1.5, prerequisites: ['CSE114']),
        CourseModel(code: 'CSE-EL2', title: 'Elective-II (specialization)', credit: 3.0),
      ],
      // Semester 10
      [
        CourseModel(code: 'CSE413', title: 'Computer Architecture and Organization', credit: 3.0, prerequisites: ['CSE223']),
        CourseModel(code: 'CSE-EL3', title: 'Elective-III (specialization)', credit: 3.0),
        CourseModel(code: 'CSE-EL4', title: 'Elective-IV (specialization)', credit: 3.0),
        CourseModel(code: 'CSE498', title: 'Capstone Project Phase-I', credit: 3.0),
      ],
      // Semester 11
      [
        CourseModel(code: 'ECO426', title: 'Engineering Economics', credit: 3.0),
        CourseModel(code: 'CSE-EL5', title: 'Elective-V (specialization)', credit: 3.0),
        CourseModel(code: 'CSE-EL6', title: 'Elective-VI (specialization)', credit: 3.0),
        CourseModel(code: 'CSE499', title: 'Capstone Project Phase-II', credit: 3.0, prerequisites: ['CSE498']),
      ],
      // Semester 12
      [
        // Graduation/Clearance (0 credits)
      ]
    ],
    "Tri": [
      // Semester 1
      [
        CourseModel(code: 'ENG101', title: 'Basic Functional English and English Spoken', credit: 3.0),
        CourseModel(code: 'MAT101', title: 'Mathematics - I', credit: 3.0),
        CourseModel(code: 'CSE112', title: 'Computer Fundamentals', credit: 3.0),
        CourseModel(code: 'CSE115', title: 'Introduction to Biology and Chemistry for Computation', credit: 3.0),
      ],
      // Semester 2
      [
        CourseModel(code: 'ENG102', title: 'Writing and Comprehension', credit: 3.0, prerequisites: ['ENG101']),
        CourseModel(code: 'MAT102', title: 'Mathematics-II: Calculus, Complex Variables and Linear Algebra', credit: 3.0, prerequisites: ['MAT101']),
        CourseModel(code: 'PHY101', title: 'Physics - I', credit: 3.0),
        CourseModel(code: 'CSE113', title: 'Programming and Problem Solving', credit: 3.0),
        CourseModel(code: 'CSE114', title: 'Programming and Problem Solving Lab', credit: 1.5),
      ],
      // Semester 3 — CORRECTED
      [
        CourseModel(code: 'PHY102', title: 'Physics - II', credit: 3.0, prerequisites: ['PHY101']),
        CourseModel(code: 'PHY103', title: 'Physics - II Lab', credit: 1.5, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE121', title: 'Electrical Circuits', credit: 3.0, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE122', title: 'Electrical Circuits Lab', credit: 1.5, prerequisites: ['PHY101']),
        CourseModel(code: 'CSE123', title: 'Data Structure', credit: 3.0, prerequisites: ['CSE113']),
        CourseModel(code: 'CSE124', title: 'Data Structure Lab', credit: 1.5, prerequisites: ['CSE114']),
      ],
      // Semester 4
      [
        CourseModel(code: 'MAT211', title: 'Engineering Mathematics', credit: 3.0, prerequisites: ['MAT102']),
        CourseModel(code: 'CSE212', title: 'Discrete Mathematics', credit: 3.0),
        CourseModel(code: 'CSE213', title: 'Algorithms', credit: 3.0, prerequisites: ['CSE123']),
        CourseModel(code: 'CSE214', title: 'Algorithms Lab', credit: 1.5, prerequisites: ['CSE124']),
        CourseModel(code: 'BNS101', title: 'Bangladesh Studies (History of Independence and Contemporary Issues)', credit: 3.0),
      ],
      // Semester 5
      [
        CourseModel(code: 'AOL101', title: 'Art of Living', credit: 3.0),
        CourseModel(code: 'CSE215', title: 'Electronic Devices and Circuits', credit: 3.0, prerequisites: ['CSE121']),
        CourseModel(code: 'CSE216', title: 'Electronic Devices and Circuits Lab', credit: 1.5, prerequisites: ['CSE122']),
        CourseModel(code: 'CSE221', title: 'Object Oriented Programming', credit: 3.0, prerequisites: ['CSE113', 'CSE213']),
        CourseModel(code: 'CSE222', title: 'Object Oriented Programming Lab', credit: 1.5, prerequisites: ['CSE114', 'CSE214']),
      ],
      // Semester 6
      [
        CourseModel(code: 'CSE223', title: 'Digital Logic Design', credit: 3.0, prerequisites: ['CSE121', 'CSE215']),
        CourseModel(code: 'CSE224', title: 'Digital Logic Design Lab', credit: 1.5, prerequisites: ['CSE122', 'CSE216']),
        CourseModel(code: 'CSE225', title: 'Data Communication', credit: 3.0, prerequisites: ['CSE112']),
        CourseModel(code: 'CSE227', title: 'Systems Analysis and Design', credit: 3.0, prerequisites: ['CSE113', 'CSE212']),
        CourseModel(code: 'CSE228', title: 'Theory of Computation', credit: 3.0, prerequisites: ['CSE212']),
      ],
      // Semester 7
      [
        CourseModel(code: 'CSE226', title: 'Numerical Methods', credit: 3.0, prerequisites: ['MAT211']),
        CourseModel(code: 'CSE311', title: 'Database Management System', credit: 3.0, prerequisites: ['CSE221']),
        CourseModel(code: 'CSE312', title: 'Database Management System Lab', credit: 1.5, prerequisites: ['CSE222']),
        CourseModel(code: 'CSE313', title: 'Compiler Design', credit: 3.0, prerequisites: ['CSE228']),
        CourseModel(code: 'CSE314', title: 'Compiler Design Lab', credit: 1.5, prerequisites: ['CSE114']),
      ],
      // Semester 8
      [
        CourseModel(code: 'CSE315', title: 'Software Engineering', credit: 3.0, prerequisites: ['CSE227']),
        CourseModel(code: 'CSE317', title: 'Microprocessor and Microcontrollers', credit: 3.0, prerequisites: ['CSE223']),
        CourseModel(code: 'CSE321', title: 'Computer Networks', credit: 3.0, prerequisites: ['CSE225']),
        CourseModel(code: 'CSE322', title: 'Computer Networks Lab', credit: 1.5, prerequisites: ['CSE221']),
        CourseModel(code: 'ACT327', title: 'Financial and Managerial Accounting', credit: 3.0),
      ],
      // Semester 9
      [
        CourseModel(code: 'STA101', title: 'Statistics and Probability', credit: 3.0, prerequisites: ['MAT211']),
        CourseModel(code: 'CSE316', title: 'Artificial Intelligence', credit: 3.0),
        CourseModel(code: 'CSE323', title: 'Operating Systems', credit: 3.0, prerequisites: ['CSE221']),
        CourseModel(code: 'CSE324', title: 'Operating Systems Lab', credit: 1.5, prerequisites: ['CSE222']),
        CourseModel(code: 'CSE-EL1', title: 'Elective-I (specialization)', credit: 3.0),
      ],
      // Semester 10
      [
        CourseModel(code: 'CSE325', title: 'Instrumentation and Control', credit: 3.0, prerequisites: ['CSE215']),
        CourseModel(code: 'CSE326', title: 'Social and Professional Issues in Computing', credit: 3.0),
        CourseModel(code: 'CSE411', title: 'Computer Graphics', credit: 3.0, prerequisites: ['CSE113']),
        CourseModel(code: 'CSE412', title: 'Computer Graphics Lab', credit: 1.5, prerequisites: ['CSE114']),
        CourseModel(code: 'CSE-EL2', title: 'Elective-II (specialization)', credit: 3.0),
      ],
      // Semester 11
      [
        CourseModel(code: 'CSE413', title: 'Computer Architecture and Organization', credit: 3.0, prerequisites: ['CSE223']),
        CourseModel(code: 'CSE-EL3', title: 'Elective-III (specialization)', credit: 3.0),
        CourseModel(code: 'CSE-EL4', title: 'Elective-IV (specialization)', credit: 3.0),
        CourseModel(code: 'CSE498', title: 'Capstone Project Phase-I', credit: 3.0),
      ],
      // Semester 12
      [
        CourseModel(code: 'ECO426', title: 'Engineering Economics', credit: 3.0),
        CourseModel(code: 'CSE-EL5', title: 'Elective-V (specialization)', credit: 3.0),
        CourseModel(code: 'CSE-EL6', title: 'Elective-VI (specialization)', credit: 3.0),
        CourseModel(code: 'CSE499', title: 'Capstone Project Phase-II', credit: 3.0, prerequisites: ['CSE498']),
      ]
    ]
  };
}

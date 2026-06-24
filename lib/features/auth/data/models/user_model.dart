import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// The canonical user model used across the entire app.
///
/// Fields:
///   - [uid]: Unique session user ID (renamed from id)
///   - [name]: Student's name
///   - [email]: Student's email
///   - [studentId]: Student's official ID
///   - [department]: Student's department
///   - [profileCompleted]: Whether student completed academic wizard
///   - [createdAt]: Account creation time
class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String studentId;
  final String department;
  final bool profileCompleted;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
    required this.department,
    required this.profileCompleted,
    required this.createdAt,
  });

  /// Creates a new user with a generated UUID. Used during Sign Up.
  factory UserModel.create({required String name, required String email}) {
    return UserModel(
      uid: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      studentId: '',
      department: '',
      profileCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) => UserModel(
        uid: (map['uid'] ?? map['id'] ?? '') as String,
        name: (map['name'] ?? '') as String,
        email: (map['email'] ?? '') as String,
        studentId: (map['studentId'] ?? '') as String,
        department: (map['department'] ?? '') as String,
        profileCompleted: (map['profileCompleted'] ?? false) as bool,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'studentId': studentId,
        'department': department,
        'profileCompleted': profileCompleted,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? studentId,
    String? department,
    bool? profileCompleted,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        studentId,
        department,
        profileCompleted,
        createdAt,
      ];
}

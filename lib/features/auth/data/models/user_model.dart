import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// The canonical user model used across the entire app.
///
/// Firebase-ready: a `UserModel.fromFirebaseUser(User user)` factory can be
/// added here when switching to `FirebaseAuthRepository`.
class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  /// Creates a new user with a generated UUID. Used during Sign Up.
  factory UserModel.create({required String name, required String email}) {
    return UserModel(
      id: const Uuid().v4(),
      name: name.trim(),
      email: email.trim().toLowerCase(),
    );
  }

  factory UserModel.fromMap(Map<dynamic, dynamic> map) => UserModel(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
      };

  @override
  List<Object?> get props => [id, name, email];
}

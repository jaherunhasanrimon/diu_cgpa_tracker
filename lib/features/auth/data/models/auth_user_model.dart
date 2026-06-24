/// Represents a locally-authenticated user.
/// Stored as a raw map under Hive key `'auth_user'`.
class AuthUserModel {
  final String name;
  final String email;

  /// SHA-256 hex digest of the password. Never stored in plaintext.
  final String passwordHash;

  const AuthUserModel({
    required this.name,
    required this.email,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
      };

  factory AuthUserModel.fromMap(Map data) => AuthUserModel(
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        passwordHash: data['passwordHash'] as String? ?? '',
      );
}

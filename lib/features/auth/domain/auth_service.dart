import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import 'auth_status.dart';
import '../../academic/repository/student_repository.dart';

/// Domain service that sits between [AuthNotifier] and [IAuthRepository].
///
/// Responsibilities:
///   - Orchestrate auth operations
///   - Determine [AuthStatus] by combining auth + profile state
///   - Isolate business rules from both the UI layer and data layer
///
/// When adding Firebase, only [IAuthRepository] changes — [AuthService] stays.
class AuthService {
  final IAuthRepository _authRepository;
  final StudentRepository _studentRepository;

  AuthService({
    required IAuthRepository authRepository,
    required StudentRepository studentRepository,
  })  : _authRepository = authRepository,
        _studentRepository = studentRepository;

  // ── Session queries ───────────────────────────────────────────────────────

  /// Returns the currently signed-in user, or `null`.
  UserModel? getCurrentUser() => _authRepository.getCurrentUser();

  /// Determines the full [AuthStatus] by combining stored user + profile flag.
  ///
  /// Called synchronously on app start — both Hive reads are sync.
  AuthStatus resolveInitialStatus() {
    final user = _authRepository.getCurrentUser();
    if (user == null) return AuthStatus.unauthenticated;
    return _profileStatus(user);
  }

  /// Determines the [AuthStatus] for an already-authenticated [user].
  AuthStatus resolveStatusForUser(UserModel user) => _profileStatus(user);

  // ── Auth operations ───────────────────────────────────────────────────────

  /// Creates a new account. Returns the new [UserModel].
  /// Throws [AuthException] on failure.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    String studentId = '',
  }) =>
      _authRepository.signUp(
        name: name,
        email: email,
        password: password,
        studentId: studentId,
      );

  /// Verifies credentials. Returns the signed-in [UserModel].
  /// Throws [AuthException] on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) =>
      _authRepository.signIn(email: email, password: password);

  /// Authenticates using Google Sign-In.
  Future<UserModel> signInWithGoogle() => _authRepository.signInWithGoogle();

  /// Requests a password reset link.
  Future<void> sendPasswordResetEmail(String email) =>
      _authRepository.sendPasswordResetEmail(email);

  /// Ends the current session.
  Future<void> signOut() => _authRepository.signOut();

  /// Permanently deletes the auth account (full app reset).
  Future<void> deleteAccount() => _authRepository.deleteAccount();

  /// Updates the current user's profile with registration details.
  Future<UserModel> updateProfile({
    required String studentId,
    required String department,
    required bool profileCompleted,
  }) =>
      _authRepository.updateProfile(
        studentId: studentId,
        department: department,
        profileCompleted: profileCompleted,
      );

  // ── Private helpers ───────────────────────────────────────────────────────

  AuthStatus _profileStatus(UserModel user) {
    if (user.profileCompleted || _studentRepository.hasStudent()) {
      return AuthStatus.authenticatedWithProfile;
    }
    return AuthStatus.authenticatedWithoutProfile;
  }
}

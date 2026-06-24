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
    return _profileStatus();
  }

  /// Determines the [AuthStatus] for an already-authenticated [user].
  AuthStatus resolveStatusForUser(UserModel user) => _profileStatus();

  // ── Auth operations ───────────────────────────────────────────────────────

  /// Creates a new account. Returns the new [UserModel].
  /// Throws [AuthException] on failure.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) =>
      _authRepository.signUp(name: name, email: email, password: password);

  /// Verifies credentials. Returns the signed-in [UserModel].
  /// Throws [AuthException] on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) =>
      _authRepository.signIn(email: email, password: password);

  /// Ends the current session.
  Future<void> signOut() => _authRepository.signOut();

  /// Permanently deletes the auth account (full app reset).
  Future<void> deleteAccount() => _authRepository.deleteAccount();

  // ── Private helpers ───────────────────────────────────────────────────────

  AuthStatus _profileStatus() => _studentRepository.hasStudent()
      ? AuthStatus.authenticatedWithProfile
      : AuthStatus.authenticatedWithoutProfile;
}

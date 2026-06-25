import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../domain/auth_service.dart';
import '../domain/auth_status.dart';
import '../../academic/repository/student_repository.dart';

// ── Auth Status is defined in domain/auth_status.dart ────────────────────────
// Re-exported here for convenience so callers only need to import auth_provider.
export '../domain/auth_status.dart';

// ── Auth State ────────────────────────────────────────────────────────────────

class AuthState {
  final AuthStatus status;
  final UserModel? user;

  /// Non-null when the last operation produced a user-facing error.
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  // ── Convenience getters ────────────────────────────────────────────────────

  bool get isLoading => status == AuthStatus.loading;

  bool get isAuthenticated =>
      status == AuthStatus.authenticatedWithoutProfile ||
      status == AuthStatus.authenticatedWithProfile;

  bool get hasProfile => status == AuthStatus.authenticatedWithProfile;

  @override
  String toString() =>
      'AuthState(status: $status, user: ${user?.email}, error: $errorMessage)';
}

// ── DI Providers ──────────────────────────────────────────────────────────────

/// Inject [LocalAuthRepository] now; swap for [FirebaseAuthRepository] later.
/// This is the ONLY line to change when migrating to Firebase auth.
final authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => LocalAuthRepository(),
);

final _authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    authRepository: ref.watch(authRepositoryProvider),
    studentRepository: StudentRepository(),
  ),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;

  AuthNotifier(this._service)
      : super(_resolveInitialState(_service));

  /// Determines the full auth state synchronously from Hive on startup.
  /// No async needed — Hive reads are synchronous.
  static AuthState _resolveInitialState(AuthService service) {
    final status = service.resolveInitialStatus();
    final user = service.getCurrentUser();
    return AuthState(status: status, user: user);
  }

  // ── Operations ─────────────────────────────────────────────────────────────

  /// Creates a new account.
  /// On success → status becomes [AuthStatus.authenticatedWithoutProfile].
  /// On failure → status returns to [AuthStatus.unauthenticated] with error.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String studentId = '',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signUp(
        name: name,
        email: email,
        password: password,
        studentId: studentId,
      );
      state = AuthState(
        status: AuthStatus.authenticatedWithoutProfile,
        user: user,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Signs in using Google.
  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signInWithGoogle();
      final resolvedStatus = _service.resolveStatusForUser(user);
      state = AuthState(status: resolvedStatus, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Google Sign-In failed. Please try again.',
      );
    }
  }

  /// Sends a password reset request email.
  Future<void> sendPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _service.sendPasswordResetEmail(email);
      // Return to unauthenticated status but clear error state
      state = state.copyWith(status: AuthStatus.unauthenticated, clearError: true);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Password reset request failed. Please try again.',
      );
    }
  }

  /// Signs in with email + password.
  /// On success → status becomes [AuthStatus.authenticatedWithProfile] or
  /// [AuthStatus.authenticatedWithoutProfile] depending on profile existence.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _service.signIn(email: email, password: password);
      final resolvedStatus = _service.resolveStatusForUser(user);
      state = AuthState(status: resolvedStatus, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
    }
  }

  /// Called by [RegistrationWizardScreen] after the academic profile is saved.
  /// Transitions from [AuthStatus.authenticatedWithoutProfile] →
  /// [AuthStatus.authenticatedWithProfile], which causes the router to
  /// redirect to `/dashboard` automatically.
  Future<void> markProfileComplete({
    required String studentId,
    required String department,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final updatedUser = await _service.updateProfile(
        studentId: studentId,
        department: department,
        profileCompleted: true,
      );
      state = AuthState(
        status: AuthStatus.authenticatedWithProfile,
        user: updatedUser,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticatedWithoutProfile,
        errorMessage: 'Failed to update profile completion: ${e.toString()}',
      );
    }
  }

  /// Signs out — clears session state. Data stays in Hive for next sign-in.
  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Permanently deletes the auth account (full app reset).
  Future<void> deleteAccount() async {
    state = state.copyWith(status: AuthStatus.loading, clearUser: true);
    await _service.deleteAccount();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clears a displayed error without changing the auth status.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ── Root Provider ─────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(_authServiceProvider)),
);

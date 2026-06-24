/// The four possible authentication states of the app.
///
/// Defined in its own file to break any circular imports between
/// [AuthService] (domain) and [AuthNotifier] (provider).
enum AuthStatus {
  /// App is determining auth state (shown during splash / async init).
  loading,

  /// No account exists or the user has signed out.
  unauthenticated,

  /// Account exists but the academic registration wizard is not complete.
  authenticatedWithoutProfile,

  /// Account exists AND academic profile has been saved.
  authenticatedWithProfile,
}

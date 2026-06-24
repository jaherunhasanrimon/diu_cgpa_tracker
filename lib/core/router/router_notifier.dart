import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';

/// Bridges [authProvider] with GoRouter's redirect mechanism.
///
/// Whenever [AuthState] changes, [notifyListeners] is called, which triggers
/// GoRouter to re-evaluate its `redirect` function. No screen navigates
/// directly — they only mutate [AuthState].
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Watch auth state changes and forward them to GoRouter.
    _ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  /// The single source of truth for where the user should be.
  ///
  /// | Status                        | Allowed routes          | Redirect to        |
  /// |-------------------------------|-------------------------|--------------------|
  /// | loading                       | `/` only                | null (stay)        |
  /// | unauthenticated               | public routes           | `/auth`            |
  /// | authenticatedWithoutProfile   | `/register-wizard` only | `/register-wizard` |
  /// | authenticatedWithProfile      | app routes              | `/dashboard`       |
  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final loc = state.uri.path;

    switch (authState.status) {
      case AuthStatus.loading:
        // Stay on splash while resolving.
        return loc == '/' ? null : '/';

      case AuthStatus.unauthenticated:
        const publicRoutes = ['/', '/onboarding', '/auth', '/login', '/register'];
        return publicRoutes.contains(loc) ? null : '/auth';

      case AuthStatus.authenticatedWithoutProfile:
        return loc == '/register-wizard' ? null : '/register-wizard';

      case AuthStatus.authenticatedWithProfile:
        const appRoutes = ['/dashboard', '/cgpa-details'];
        final isAppRoute = appRoutes.any((r) => loc.startsWith(r));
        return isAppRoute ? null : '/dashboard';
    }
  }
}

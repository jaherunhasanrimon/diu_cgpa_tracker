import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/registration/registration_wizard_screen.dart';
import '../../features/auth/presentation/auth_gate_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/cgpa/presentation/cgpa_details_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'router_notifier.dart';

/// Riverpod provider that exposes the app's [GoRouter].
///
/// The router is state-aware: it holds a [RouterNotifier] that listens to
/// [authProvider] and triggers GoRouter's redirect whenever auth state changes.
///
/// **This replaces the old `AppRouter.router` static.**
/// Usage in `app.dart`: `ref.watch(routerProvider)`.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    // Re-evaluate redirect whenever auth state changes.
    refreshListenable: notifier,
    redirect: notifier.redirect,

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthGateScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/register-wizard',
        builder: (context, state) => const RegistrationWizardScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/cgpa-details',
        builder: (context, state) => const CgpaDetailsScreen(),
      ),
    ],
  );
});
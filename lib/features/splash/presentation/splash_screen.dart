import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for branding splash to display.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Navigate to the auth gate. RouterNotifier's redirect will intercept
    // and send the user to the correct destination based on AuthStatus:
    //   • unauthenticated           → stays on /auth (gate)
    //   • authenticatedWithoutProfile → /register-wizard
    //   • authenticatedWithProfile    → /dashboard
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 90,
            ),

            const SizedBox(height: 24),

            Text(
              'DIU CGPA Tracker',
              style: AppTextStyles.headingMedium.copyWith(
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Academic Intelligence Platform',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
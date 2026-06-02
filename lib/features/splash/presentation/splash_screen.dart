import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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

    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    context.go('/onboarding');
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
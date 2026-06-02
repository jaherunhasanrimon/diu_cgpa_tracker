import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(
          AppSpacing.lg,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(
              'Login Screen',
              style: AppTextStyles.headingMedium,
            ),

          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_text_styles.dart';

class AcademicExceptionStep extends ConsumerWidget {
  const AcademicExceptionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Exceptions',
            style: AppTextStyles.headingMedium,
          ),

          const SizedBox(height: AppSpacing.lg),

          const Text(
            'If you have any academic exceptions (withdrawals, repeats, etc.), list them here.',
          ),
        ],
      ),
    );
  }
}
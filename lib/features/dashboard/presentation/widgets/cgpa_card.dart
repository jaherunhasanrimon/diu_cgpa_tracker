import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

class CgpaCard extends StatelessWidget {
  final double cgpa;

  const CgpaCard({super.key, required this.cgpa});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .05), blurRadius: 20),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text("Current CGPA", style: AppTextStyles.headingMedium),

          const SizedBox(height: 15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              Text(
                cgpa.toStringAsFixed(2),

                style: const TextStyle(
                  fontSize: 42,

                  fontWeight: FontWeight.bold,

                  color: Color(0xff4F46E5),
                ),
              ),

              const Text(
                "/4.0",

                style: TextStyle(fontSize: 26, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Text("Keep it up! You're doing great 🚀"),
        ],
      ),
    );
  }
}

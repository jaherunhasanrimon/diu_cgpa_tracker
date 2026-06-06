import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/hive_service.dart';
import '../../cgpa/providers/cgpa_provider.dart';

import 'widgets/cgpa_card.dart';
import 'widgets/academic_tool_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpa = ref.watch(cgpaProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF8F8FB),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Center(
                child: Text(
                  "CGPA Planner",

                  style: TextStyle(
                    fontSize: 24,

                    fontWeight: FontWeight.bold,

                    color: Color(0xff312E81),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () {
                  context.push('/cgpa-details');
                },

                child: CgpaCard(cgpa: cgpa),
              ),

              const SizedBox(height: 30),

              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await HiveService.clear();

                    if (!context.mounted) {
                      return;
                    }

                    context.go('/auth');
                  },

                  child: const Text('Reset App'),
                ),
              ),

              const Text(
                "Academic Tools",

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,

                  mainAxisSpacing: 16,

                  crossAxisSpacing: 16,

                  children: const [
                    AcademicToolCard(
                      icon: Icons.refresh,

                      title: "Retake Analyzer",

                      subtitle: "Boost potential",
                    ),

                    AcademicToolCard(
                      icon: Icons.track_changes,

                      title: "Target CGPA",

                      subtitle: "Goal calculator",
                    ),

                    AcademicToolCard(
                      icon: Icons.calendar_month,

                      title: "Semester Planner",

                      subtitle: "Schedule classes",
                    ),

                    AcademicToolCard(
                      icon: Icons.science,

                      title: "What-if Sandbox",

                      subtitle: "Test scenarios",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

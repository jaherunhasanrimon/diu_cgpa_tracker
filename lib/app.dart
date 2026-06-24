import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class DiuCgpaTrackerApp extends ConsumerWidget {
  const DiuCgpaTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // routerProvider creates a GoRouter with RouterNotifier that watches
    // authProvider and triggers redirect whenever auth state changes.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DIU CGPA Tracker',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
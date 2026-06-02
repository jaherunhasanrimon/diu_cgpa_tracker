import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class DiuCgpaTrackerApp extends StatelessWidget {
  const DiuCgpaTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'DIU CGPA Tracker',

      theme: AppTheme.lightTheme,

      routerConfig: AppRouter.router,
    );
  }
}
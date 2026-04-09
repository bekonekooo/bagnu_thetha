import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class BagnuThetaApp extends StatelessWidget {
  const BagnuThetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BagnuTheta',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
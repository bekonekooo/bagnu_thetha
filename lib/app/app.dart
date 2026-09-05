import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';
import 'theme.dart';

class BagnuThetaApp extends StatelessWidget {
  const BagnuThetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Yeniden Kendine',
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}

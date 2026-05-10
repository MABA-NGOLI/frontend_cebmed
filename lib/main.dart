import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'views/entry/splash_view.dart';
import 'views/entry/welcome_view.dart';
import 'views/main_shell.dart';

enum EntryStage {
  splash,
  welcome,
  app,
}

void main() {
  runApp(const CebMedApp());
}

class CebMedApp extends StatefulWidget {
  const CebMedApp({super.key});

  @override
  State<CebMedApp> createState() => _CebMedAppState();
}

class _CebMedAppState extends State<CebMedApp> {
  EntryStage stage = EntryStage.splash;

  @override
  Widget build(BuildContext context) {
    Widget home;

    switch (stage) {
      case EntryStage.splash:
        home = SplashView(
          onResolved: (_) {
            setState(() {
              stage = EntryStage.welcome;
            });
          },
        );
        break;

      case EntryStage.welcome:
        home = WelcomeView(
          onLogin: () {
            setState(() {
              stage = EntryStage.app;
            });
          },
          onSignup: () {
            setState(() {
              stage = EntryStage.app;
            });
          },
        );
        break;

      case EntryStage.app:
        home = MainShell(
          onLogout: () {
            setState(() {
              stage = EntryStage.welcome;
            });
          },
        );
        break;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CebMed',
      theme: AppTheme.light(),
      home: home,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'views/entry/splash_view.dart';
import 'views/entry/welcome_view.dart';
import 'views/main_shell.dart';

enum EntryStage {
  splash,
  welcome,
  app,
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
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
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

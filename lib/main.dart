import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'services/caregiver_mode_service.dart';
import 'services/notification_service.dart';
import 'views/authentication/login_view.dart';
import 'views/authentication/forgot_password_view.dart';
import 'views/authentication/role_selection_view.dart';
import 'views/authentication/signup_view.dart';
import 'views/entry/splash_view.dart' show SplashResult, SplashView;
import 'views/entry/welcome_view.dart';
import 'views/main_shell.dart';

enum EntryStage {
  splash,
  welcome,
  login,
  forgotPassword,
  signup,
  roleSelection,
  app,
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await NotificationService.init();
  runApp(const CebMedApp());
}

class CebMedApp extends StatefulWidget {
  const CebMedApp({super.key});

  @override
  State<CebMedApp> createState() => _CebMedAppState();
}

class _CebMedAppState extends State<CebMedApp> {
  EntryStage stage = EntryStage.splash;
  bool _isCaregiver = false;
  bool _openCaregiverSetupOnAppStart = false;

  @override
  void initState() {
    super.initState();
    _loadSavedRole();
  }

  Future<void> _loadSavedRole() async {
    final saved = await CaregiverModeService.isCaregiver();
    if (!mounted) return;
    setState(() {
      _isCaregiver = saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget home;

    switch (stage) {
      case EntryStage.splash:
        home = SplashView(
          onResolved: (result) {
            setState(() {
              stage = result == SplashResult.app
                  ? EntryStage.app
                  : EntryStage.welcome;
            });
          },
        );
        break;

      case EntryStage.welcome:
        home = WelcomeView(
          onLogin: () {
            setState(() {
              stage = EntryStage.login;
            });
          },
          onSignup: () {
            setState(() {
              stage = EntryStage.signup;
            });
          },
        );
        break;

      case EntryStage.login:
        home = LoginView(
          onBack: () {
            setState(() {
              _openCaregiverSetupOnAppStart = false;
              stage = EntryStage.welcome;
            });
          },
          onSuccess: () {
            setState(() {
              stage = EntryStage.roleSelection;
            });
          },
          onGoSignup: () {
            setState(() {
              stage = EntryStage.signup;
            });
          },
          onForgotPassword: () {
            setState(() {
              stage = EntryStage.forgotPassword;
            });
          },
        );
        break;

      case EntryStage.forgotPassword:
        home = ForgotPasswordView(
          onBack: () {
            setState(() {
              stage = EntryStage.login;
            });
          },
          onSuccess: () {
            setState(() {
              stage = EntryStage.login;
            });
          },
        );
        break;

      case EntryStage.signup:
        home = SignupView(
          onBack: () {
            setState(() {
              _openCaregiverSetupOnAppStart = false;
              stage = EntryStage.welcome;
            });
          },
          onSuccess: () {
            setState(() {
              stage = EntryStage.roleSelection;
            });
          },
          onGoLogin: () {
            setState(() {
              stage = EntryStage.login;
            });
          },
        );
        break;

      case EntryStage.roleSelection:
        home = RoleSelectionView(
          onSelectRole: (role) async {
            final isCaregiver = role == UserRole.caregiver;
            await CaregiverModeService.setIsCaregiver(isCaregiver);
            if (!mounted) return;
            setState(() {
              _isCaregiver = isCaregiver;
              _openCaregiverSetupOnAppStart = isCaregiver;
              stage = EntryStage.app;
            });
          },
        );
        break;
      case EntryStage.app:
        home = MainShell(
          isCaregiver: _isCaregiver,
          openCaregiverSetupOnStart: _openCaregiverSetupOnAppStart,
          onLogout: () {
            setState(() {
              _openCaregiverSetupOnAppStart = false;
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
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: home,
    );
  }
}

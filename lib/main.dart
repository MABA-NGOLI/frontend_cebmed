import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'services/api_service.dart';
import 'services/caregiver_mode_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/authentication/forgot_password_view.dart';
import 'views/authentication/login_view.dart';
import 'views/authentication/role_selection_view.dart';
import 'views/authentication/signup_view.dart';
import 'views/entry/splash_view.dart' show SplashResult, SplashView;
import 'views/entry/welcome_view.dart';
import 'views/main_shell.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

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
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initializeDateFormatting('fr_FR');
  await NotificationService.init();
  runApp(const CebMedApp());
}

class CebMedApp extends StatefulWidget {
  const CebMedApp({super.key});

  @override
  State<CebMedApp> createState() => _CebMedAppState();
}

class _CebMedAppState extends State<CebMedApp> with WidgetsBindingObserver {
  EntryStage stage = EntryStage.splash;
  bool _isCaregiver = false;
  bool _openCaregiverSetupOnAppStart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSavedRole();
  }

  @override
  void dispose() {
    ApiService.onSessionExpired = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Recharge le rôle choisi précédemment pour éviter de redemander à chaque ouverture.
  Future<void> _loadSavedRole() async {
    final saved = await CaregiverModeService.isCaregiver();
    if (!mounted) return;
    setState(() {
      _isCaregiver = saved;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && stage == EntryStage.app) {
      ApiService.refreshIfNeeded()
          .then((_) => NotificationService.syncFcmToken())
          .catchError((_) {
            // onSessionExpired gere deja le retour vers la connexion.
          });
    }
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
        home = const ForgotPasswordView();
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
        ApiService.onSessionExpired = () {
          if (mounted) {
            setState(() {
              _openCaregiverSetupOnAppStart = false;
              stage = EntryStage.welcome;
            });
          }
        };
        home = MainShell(
          isCaregiver: _isCaregiver,
          openCaregiverSetupOnStart: _openCaregiverSetupOnAppStart,
          onChangeRole: () {
            setState(() {
              _openCaregiverSetupOnAppStart = false;
              stage = EntryStage.roleSelection;
            });
          },
          onCancelCaregiverSetup: () async {
            await CaregiverModeService.setIsCaregiver(false);
            if (!mounted) return;
            setState(() {
              _isCaregiver = false;
              _openCaregiverSetupOnAppStart = false;
              stage = EntryStage.roleSelection;
            });
          },
          onLogout: () {
            ApiService.onSessionExpired = null;
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

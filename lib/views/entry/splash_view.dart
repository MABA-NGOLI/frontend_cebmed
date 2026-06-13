import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/notification_service.dart';

enum SplashResult {
  welcome,
  app,
}

class SplashView extends StatefulWidget {
  const SplashView({
    super.key,
    required this.onResolved,
  });

  final ValueChanged<SplashResult> onResolved;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      ApiService.loadTokens(),
    ]);

    if (!mounted) return;

    final hasTokens = results[1] as bool;
    if (hasTokens) {
      await NotificationService.syncFcmToken();
    }
    widget.onResolved(hasTokens ? SplashResult.app : SplashResult.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.secondary,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

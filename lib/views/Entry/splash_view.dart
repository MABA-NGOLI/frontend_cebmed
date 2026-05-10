import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

enum SplashResult {
  welcome,
  login,
  faceId,
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
    await Future.delayed(
      const Duration(seconds: 2),
    );

    try {
      if (ApiService.token == null) {
        if (!mounted) return;

        widget.onResolved(SplashResult.welcome);
        return;
      }

      await ApiService.getMe();

      if (!mounted) return;

      widget.onResolved(SplashResult.app);
    } catch (_) {
      if (!mounted) return;

      widget.onResolved(SplashResult.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
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
import 'package:flutter/material.dart';

enum SplashResult {
  welcome,
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
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    widget.onResolved(SplashResult.welcome);
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

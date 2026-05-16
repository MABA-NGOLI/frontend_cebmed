import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class StockView extends StatelessWidget {
  const StockView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon stock'),
      ),
      backgroundColor: AppTheme.background,
      body: const Center(
        child: Text('Page stock en cours de finalisation'),
      ),
    );
  }
}


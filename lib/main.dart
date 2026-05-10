import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'views/entry/splash_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CEBMED',
      theme: AppTheme.light(),
      home: SplashView(
        onResolved: (result) {
          print(result);
        },
      ),
    );
  }
}
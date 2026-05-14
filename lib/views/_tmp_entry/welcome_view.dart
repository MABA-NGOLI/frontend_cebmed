import 'package:flutter/material.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({
    super.key,
    required this.onLogin,
    required this.onSignup,
  });

  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              Text(
                'Bienvenue sur',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Image.asset(
                'assets/images/logo_text.png',
                width: screenWidth * 0.6,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.45,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              Text(
                'Ton assitant personnel CEB pour un esprit plus léger',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onLogin,
                  child: const Text('Se connecter'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSignup,
                  child: const Text("S'inscrire"),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: onLogout,
        child: const Text('Déconnexion'),
      ),
    );
  }
}
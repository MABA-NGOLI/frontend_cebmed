import 'package:flutter/material.dart';

import 'package:frontend_cebmed/views/home/home_view.dart';
import 'package:frontend_cebmed/views/agenda/appointment_view.dart';
import 'package:frontend_cebmed/views/ordonnances/document_view.dart';
import 'package:frontend_cebmed/views/profile/profile_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.onLogout,
  });

  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const HomeView(),
    const DocumentView(),
    AppointmentView(
      onOpenProfile: () {
        setState(() {
          _currentIndex = 3;
        });
      },
    ),
    ProfileView(onLogout: widget.onLogout),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Ordonnances',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

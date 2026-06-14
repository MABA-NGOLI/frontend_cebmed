import 'package:flutter/material.dart';

import 'package:frontend_cebmed/views/agenda/appointment_view.dart';
import 'package:frontend_cebmed/views/authentication/caregiver_add_profile_view.dart';
import 'package:frontend_cebmed/views/home/home_view.dart';
import 'package:frontend_cebmed/views/ordonnances/document_view.dart';
import 'package:frontend_cebmed/views/profile/profile_view.dart';
import 'package:frontend_cebmed/viewmodels/caregiver_hub_view_model.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.onLogout,
    this.isCaregiver = false,
    this.openCaregiverSetupOnStart = false,
  });

  final VoidCallback onLogout;
  final bool isCaregiver;
  final bool openCaregiverSetupOnStart;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final CaregiverHubViewModel _caregiverHub;
  bool _didPromptMissingCaregiverProfile = false;
  bool _isPreparingCaregiverMode = false;

  @override
  void initState() {
    super.initState();
    _caregiverHub = CaregiverHubViewModel();
    if (widget.isCaregiver) {
      _isPreparingCaregiverMode = true;
      _initializeCaregiverMode();
    }
  }

  Future<void> _initializeCaregiverMode() async {
    await _caregiverHub.initialize();
    if (!mounted || _didPromptMissingCaregiverProfile) return;

    if ((widget.openCaregiverSetupOnStart || !_caregiverHub.hasProfiles) &&
        _caregiverHub.errorMessage == null) {
      _didPromptMissingCaregiverProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openAddProfile();
        if (!mounted) return;
        setState(() {
          _isPreparingCaregiverMode = false;
        });
      });
      return;
    }

    setState(() {
      _isPreparingCaregiverMode = false;
    });
  }

  @override
  void dispose() {
    _caregiverHub.dispose();
    super.dispose();
  }

  Future<void> _openAddProfile() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CaregiverAddProfileView(viewModel: _caregiverHub),
      ),
    );

    if (added == true) {
      await _caregiverHub.refreshProfiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCaregiver && _isPreparingCaregiverMode) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final activeProfile = widget.isCaregiver
        ? _caregiverHub.activeProfile
        : null;
    final canViewDocuments =
        !widget.isCaregiver || activeProfile?.canViewDocuments == true;
    final canUploadDocuments =
        !widget.isCaregiver || activeProfile?.canUploadDocuments == true;
    final canViewAgenda =
        !widget.isCaregiver || activeProfile?.canViewAgenda == true;
    final canEditAgenda =
        !widget.isCaregiver || activeProfile?.canEditAgenda == true;

    final tabs = <_ShellTab>[
      _ShellTab(
        page: HomeView(
          isCaregiver: widget.isCaregiver,
          caregiverHub: widget.isCaregiver ? _caregiverHub : null,
          onRequestAddProfile: widget.isCaregiver ? _openAddProfile : null,
        ),
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
      ),
    ];

    if (canViewDocuments) {
      tabs.add(
        _ShellTab(
          page: DocumentView(canUploadDocuments: canUploadDocuments),
          destination: const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Ordonnances',
          ),
        ),
      );
    }

    if (canViewAgenda) {
      tabs.add(
        _ShellTab(
          page: AppointmentView(
            canEditAgenda: canEditAgenda,
            onOpenProfile: () {
              setState(() {
                _currentIndex = tabs.length - 1;
              });
            },
          ),
          destination: const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda',
          ),
        ),
      );
    }

    tabs.add(
      _ShellTab(
        page: ProfileView(
          onLogout: widget.onLogout,
          isCaregiver: widget.isCaregiver,
          caregiverHub: widget.isCaregiver ? _caregiverHub : null,
          onRequestAddProfile: widget.isCaregiver ? _openAddProfile : null,
        ),
        destination: const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ),
    );

    final selectedIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;
    if (selectedIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = selectedIndex;
        });
      });
    }

    return Scaffold(
      body: tabs[selectedIndex].page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        onDestinationSelected: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        destinations: tabs.map((tab) => tab.destination).toList(),
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({required this.page, required this.destination});

  final Widget page;
  final NavigationDestination destination;
}

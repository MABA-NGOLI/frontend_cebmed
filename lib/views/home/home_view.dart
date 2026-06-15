import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/caregiver_hub_view_model.dart';
import '../../viewmodels/home_view_model.dart';
import '../ordonnances/document_view.dart';
import '../reminders/reminder_timeline_view.dart';
import '../stock/stock_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
    this.isCaregiver = false,
    this.caregiverHub,
    this.onRequestAddProfile,
  });

  final bool isCaregiver;
  final CaregiverHubViewModel? caregiverHub;
  final VoidCallback? onRequestAddProfile;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late final HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _viewModel,
        if (widget.caregiverHub != null) widget.caregiverHub!,
      ]),
      builder: (context, _) {
        final activeProfile = widget.caregiverHub?.activeProfile;
        final canViewDocuments =
            !widget.isCaregiver || activeProfile?.canViewDocuments == true;
        final canUploadDocuments =
            !widget.isCaregiver || activeProfile?.canUploadDocuments == true;
        final canViewStock =
            !widget.isCaregiver || activeProfile?.canViewStock == true;
        final canEditStock =
            !widget.isCaregiver || activeProfile?.canEditStock == true;

        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: widget.isCaregiver ? _buildCaregiverDrawer(context) : null,
          body: SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 18),
                    _buildWeekBlock(context),
                    const SizedBox(height: 16),
                    _buildNextReminderCard(context),
                    _buildPendingNowCard(context),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              imagePath: 'assets/images/card_docs.png',
                              onTap: () {
                                if (!canViewDocuments) {
                                  _showPermissionDenied(context, 'documents');
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DocumentView(
                                      canUploadDocuments: canUploadDocuments,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ActionCard(
                              imagePath: 'assets/images/card_stock.png',
                              onTap: () {
                                if (!canViewStock) {
                                  _showPermissionDenied(context, 'stock');
                                  return;
                                }
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        StockView(canEditStock: canEditStock),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPermissionDenied(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Le patient ne vous a pas donnÃƒÂ© lÃ¢â‚¬â„¢autorisation dÃ¢â‚¬â„¢accÃƒÂ©der ÃƒÂ  cette page $label.',
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hub = widget.caregiverHub;
    final helloName = widget.isCaregiver
        ? (hub?.activeProfile?.firstName.trim().isNotEmpty == true
              ? hub!.activeProfile!.firstName
              : _viewModel.firstName)
        : _viewModel.firstName;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.softBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isCaregiver) ...[
            Text(
              'Code de partage',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              'Partagez ce code avec votre aidant',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _viewModel.shareCode,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(letterSpacing: 1.5),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: () async {
                    final ok = await _viewModel.shareCurrentCode();
                    if (!mounted || ok) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Code de partage indisponible pour le moment',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu),
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 24, height: 24),
              const SizedBox(width: 8),
              Text(
                'Hello, ${_viewModel.capitalize(helloName)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverDrawer(BuildContext context) {
    final hub = widget.caregiverHub;
    final profiles = hub?.profiles ?? const [];

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    child: Icon(Icons.person, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Aidant(e)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Personnes aidées',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: hub?.isLoading == true
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = profiles[index];
                          final isActive =
                              p.patientId == hub?.activeProfile?.patientId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person_outline),
                            title: Text(p.fullName),
                            subtitle: Text(p.status),
                            trailing: isActive
                                ? const Icon(
                                    Icons.check,
                                    color: AppTheme.primaryPink,
                                  )
                                : null,
                            onTap: () async {
                              await hub?.selectProfile(p);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Profil actif: ${p.fullName}'),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onRequestAddProfile?.call();
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un profil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextReminderCard(BuildContext context) {
    if (_viewModel.isLoadingReminder) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
        ),
      );
    }

    final reminder = _viewModel.nextReminder;
    final initialDay = reminder?.scheduledAt.toLocal() ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReminderTimelineView(initialDay: initialDay),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.softBlue.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history_rounded, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: reminder == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rappels',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                            ),
                            const SizedBox(height: 2),
                            Text('Voir l\'historique', style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prochain rappel',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    reminder.medicationName,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  reminder.timeLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingNowCard(BuildContext context) {
    final intake = _viewModel.pendingNowIntake;
    if (intake == null) return const SizedBox.shrink();

    final isOverdue = intake.scheduledAt.toLocal().isBefore(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPink.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOverdue ? 'En retard' : 'Maintenant',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${intake.scheduledAt.toLocal().hour.toString().padLeft(2, '0')}:${intake.scheduledAt.toLocal().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              intake.medicationName,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (intake.treatment.dosage.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                intake.treatment.dosage,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: _viewModel.isValidating
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : GestureDetector(
                      onTap: _viewModel.validateNowIntake,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Confirmer la prise',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryPink,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekBlock(BuildContext context) {
    final fr = DateFormat('d MMM yyyy', 'fr_FR');
    final weekday = DateFormat('EEEE', 'fr_FR');
    final weekStart = _viewModel.weekStart(_viewModel.focusedDay);
    final weekEnd = _viewModel.weekEnd(_viewModel.focusedDay);
    final weekRangeLabel =
        '${DateFormat('d MMM', 'fr_FR').format(weekStart)} - ${DateFormat('d MMM', 'fr_FR').format(weekEnd)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _viewModel.capitalize(weekday.format(_viewModel.selectedDay)),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                fr.format(_viewModel.selectedDay),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: _viewModel.goPreviousWeek,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  weekRangeLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: _viewModel.goNextWeek,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _viewModel.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_viewModel.selectedDay, day),
              eventLoader: _viewModel.appointmentsForDay,
              calendarFormat: CalendarFormat.week,
              availableCalendarFormats: const {CalendarFormat.week: 'Semaine'},
              headerVisible: false,
              startingDayOfWeek: StartingDayOfWeek.monday,
              onDaySelected: _viewModel.onDaySelected,
              onPageChanged: _viewModel.onPageChanged,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                markersMaxCount: 1,
                todayDecoration: BoxDecoration(
                  color: AppTheme.softBlue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.imagePath, required this.onTap});

  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 158,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFE9BDE0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/appointment.dart';
import '../../theme/app_theme.dart';
import 'package:frontend_cebmed/services/api_service.dart';
import 'package:frontend_cebmed/views/agenda/appointment_form_view.dart';

class AppointmentView extends StatefulWidget {
  const AppointmentView({super.key});

  @override
  State<AppointmentView> createState() => _AppointmentViewState();
}

class _AppointmentViewState extends State<AppointmentView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final ScrollController _pageScrollController = ScrollController();

  bool _isLoading = true;
  String? _error;
  List<Appointment> _appointments = const [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger les rendez-vous';
        _isLoading = false;
      });
    }
  }

  List<Appointment> _appointmentsForDay(DateTime day) {
    return _appointments.where((a) => isSameDay(a.startTime, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> _openAppointmentForm({Appointment? appointment}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentFormView(initialAppointment: appointment),
      ),
    );
    if (changed == true) {
      _loadAppointments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayAppointments = _appointmentsForDay(_selectedDay);
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = width < 360;
        final horizontal = compact ? 12.0 : 16.0;
        final maxWidth = width > 520 ? 520.0 : width;

        final isToday = isSameDay(_selectedDay, DateTime.now());
        final sectionTitle = isToday ? "Aujourd'hui" : 'Rendez-vous du jour';
        final sectionDate = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Scrollbar(
                  controller: _pageScrollController,
                  thumbVisibility: true,
                  child: CustomScrollView(
                    controller: _pageScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(horizontal, compact ? 14 : 18, horizontal, compact ? 10 : 14),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryPink,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Agenda',
                                  style: (compact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(color: AppTheme.white),
                                ),
                                SizedBox(height: compact ? 6 : 8),
                                TableCalendar<Appointment>(
                                  locale: 'fr_FR',
                                  firstDay: DateTime(2020, 1, 1),
                                  lastDay: DateTime(2100, 12, 31),
                                  focusedDay: _focusedDay,
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  eventLoader: _appointmentsForDay,
                                  headerStyle: HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.white),
                                    rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.white),
                                    titleTextStyle: (compact ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(color: AppTheme.white) ??
                                        const TextStyle(color: AppTheme.white),
                                  ),
                                  daysOfWeekStyle: const DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(color: AppTheme.white),
                                    weekendStyle: TextStyle(color: AppTheme.white),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    outsideTextStyle: const TextStyle(color: AppTheme.softPink),
                                    defaultTextStyle: TextStyle(color: AppTheme.black, fontSize: compact ? 12 : 14),
                                    weekendTextStyle: TextStyle(color: AppTheme.black, fontSize: compact ? 12 : 14),
                                    markerDecoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                                    markersMaxCount: 1,
                                    selectedDecoration: const BoxDecoration(color: AppTheme.softGreen, shape: BoxShape.circle),
                                    selectedTextStyle: const TextStyle(color: AppTheme.black),
                                    todayDecoration: BoxDecoration(
                                      color: AppTheme.softBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.white, width: 1),
                                    ),
                                    todayTextStyle: const TextStyle(color: AppTheme.black),
                                    cellMargin: EdgeInsets.all(compact ? 2 : 4),
                                  ),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontal, compact ? 12 : 18, horizontal, 0),
                          child: SizedBox(
                            width: compact ? double.infinity : 300,
                            child: OutlinedButton.icon(
                              onPressed: () => _openAppointmentForm(),
                              iconAlignment: IconAlignment.end,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text(
                                'Ajouter un rendez-vous',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.black,
                                side: const BorderSide(color: AppTheme.primaryPink),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 10 : 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontal, compact ? 12 : 18, horizontal, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sectionTitle, style: compact ? textTheme.titleMedium : textTheme.titleLarge),
                              const SizedBox(height: 2),
                              Text(sectionDate, style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      if (_isLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                                const SizedBox(height: 10),
                                TextButton(onPressed: _loadAppointments, child: const Text('Réessayer')),
                              ],
                            ),
                          ),
                        )
                      else if (_appointments.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'Aucun rendez-vous enregistre pour le moment',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                            ),
                          ),
                        )
                      else if (selectedDayAppointments.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 110),
                            child: Text(
                              'Aucun rendez-vous pour ce jour',
                              style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 110),
                          sliver: SliverList.builder(
                            itemCount: selectedDayAppointments.length,
                            itemBuilder: (context, index) => _AppointmentCard(
                              appointment: selectedDayAppointments[index],
                              compact: compact,
                              onTap: () => _openAppointmentForm(appointment: selectedDayAppointments[index]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.compact,
    required this.onTap,
  });

  final Appointment appointment;
  final bool compact;
  final VoidCallback onTap;

  String _consultationTypeLabel(String? value) {
    switch (value) {
      case 'PRESENTIAL':
        return 'Présentiel';
      case 'VIDEO':
        return 'Visio';
      case 'PHONE':
        return 'Téléphone';
      default:
        return value ?? 'Consultation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontFamily: 'Montserrat',
      fontSize: compact ? 15 : 16,
      fontWeight: FontWeight.w700,
    );
    final consultationStyle = textTheme.titleLarge?.copyWith(
      fontFamily: 'Montserrat',
      fontSize: compact ? 17 : 19,
      fontWeight: FontWeight.w700,
    );
    final labelStyle = textTheme.titleMedium?.copyWith(
      fontFamily: 'Montserrat',
      fontSize: compact ? 14 : 15,
      fontWeight: FontWeight.w700,
    );
    final valueStyle = textTheme.bodyLarge?.copyWith(
      fontFamily: 'Montserrat',
      fontSize: compact ? 13 : 14,
      fontWeight: FontWeight.w600,
      color: Colors.black54,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFDBDBDB))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 64 : 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('d MMM', 'fr_FR').format(appointment.startTime), style: textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text('${DateFormat('HH:mm').format(appointment.startTime)}', style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                    Text('${DateFormat('HH:mm').format(appointment.endTime)}', style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rendez-vous', style: titleStyle),
                    const SizedBox(height: 6),
                    Text(_consultationTypeLabel(appointment.consultationType), style: consultationStyle),
                    const SizedBox(height: 6),
                    Text('Lieu', style: labelStyle),
                    Text(appointment.location ?? '-', style: valueStyle),
                    const SizedBox(height: 4),
                    Text('Description', style: labelStyle),
                    Text(
                      (appointment.description == null || appointment.description!.trim().isEmpty)
                          ? 'Pas de description'
                          : appointment.description!,
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


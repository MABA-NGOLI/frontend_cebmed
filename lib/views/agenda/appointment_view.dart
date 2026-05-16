import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/appointment.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'package:frontend_cebmed/views/agenda/appointment_form_view.dart';

class AppointmentView extends StatefulWidget {
  const AppointmentView({super.key});

  @override
  State<AppointmentView> createState() => _AppointmentViewState();
}

class _AppointmentViewState extends State<AppointmentView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isLoading = true;
  String? _error;
  List<Appointment> _appointments = const [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
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

  Future<void> _editAppointment(Appointment appointment) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentFormView(initialAppointment: appointment),
      ),
    );

    if (updated == true) {
      await _loadAppointments();
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

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    Expanded(
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 0),
                                padding: EdgeInsets.fromLTRB(horizontal, compact ? 14 : 18, horizontal, compact ? 10 : 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryPink,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  children: [
                                    Text('Agenda', style: (compact ? textTheme.headlineSmall : textTheme.headlineMedium)?.copyWith(color: AppTheme.white)),
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
                                        titleTextStyle: (compact ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(color: AppTheme.white) ?? const TextStyle(color: AppTheme.white),
                                      ),
                                      daysOfWeekStyle: const DaysOfWeekStyle(
                                        weekdayStyle: TextStyle(color: AppTheme.white),
                                        weekendStyle: TextStyle(color: AppTheme.white),
                                      ),
                                      calendarBuilders: CalendarBuilders(
                                        markerBuilder: (context, day, events) {
                                          if (events.isEmpty) return const SizedBox.shrink();
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
                                        outsideTextStyle: const TextStyle(color: AppTheme.softPink),
                                        defaultTextStyle: TextStyle(color: AppTheme.black, fontSize: compact ? 12 : 14),
                                        weekendTextStyle: TextStyle(color: AppTheme.black, fontSize: compact ? 12 : 14),
                                        markersMaxCount: 1,
                                        markerDecoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
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
                              SizedBox(height: compact ? 12 : 18),
                              SizedBox(
                                width: compact ? double.infinity : 300,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final created = await Navigator.of(context).push<bool>(
                                        MaterialPageRoute(builder: (_) => const AppointmentFormView()),
                                      );
                                      if (created == true) _loadAppointments();
                                    },
                                    iconAlignment: IconAlignment.end,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text('Ajouter un rendez-vous', maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.bodyMedium),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.black,
                                      side: const BorderSide(color: AppTheme.primaryPink),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 10 : 12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 12 : 18),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: horizontal),
                                child: _buildAgendaSection(selectedDayAppointments, textTheme, compact),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
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

  Widget _buildAgendaSection(List<Appointment> selectedDayAppointments, TextTheme textTheme, bool compact) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
            const SizedBox(height: 10),
            TextButton(onPressed: _loadAppointments, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Text('Aucun rendez-vous enregistre pour le moment', style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
      );
    }

    final isToday = isSameDay(_selectedDay, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isToday ? 'Aujourd\'hui' : 'Rendez-vous du jour',
              style: compact ? textTheme.titleMedium : textTheme.titleLarge,
            ),
            Text(DateFormat('EEE d MMM', 'fr_FR').format(_selectedDay), style: compact ? textTheme.bodyLarge : textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 12),
        if (selectedDayAppointments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Aucun rendez-vous pour ce jour', style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          )
        else
          ListView.builder(
            itemCount: selectedDayAppointments.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) => _AppointmentCard(
              appointment: selectedDayAppointments[index],
              compact: compact,
              onEdit: () => _editAppointment(selectedDayAppointments[index]),
            ),
          ),
      ],
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.compact,
    required this.onEdit,
  });

  final Appointment appointment;
  final bool compact;
  final VoidCallback onEdit;

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
    final title = appointment.title.trim().isEmpty
        ? _consultationTypeLabel(appointment.consultationType)
        : appointment.title.trim();
    final hasDescription =
        appointment.description != null && appointment.description!.trim().isNotEmpty;

    return Container(
      child: InkWell(
        onTap: onEdit,
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
                    Text(DateFormat('d MMM', 'fr_FR').format(appointment.startTime), style: textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('HH:mm').format(appointment.startTime)} - ${DateFormat('HH:mm').format(appointment.endTime)}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: compact ? textTheme.bodyMedium : textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
                    const SizedBox(height: 2),
                    Text(
                      'Type de consultation',
                      style: compact ? textTheme.bodyMedium : textTheme.bodyLarge,
                    ),
                    Text(
                      appointment.consultationType == null || appointment.consultationType!.trim().isEmpty
                          ? 'Non renseigne'
                          : _consultationTypeLabel(appointment.consultationType),
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 3),
                    Text('Lieu', style: compact ? textTheme.bodyMedium : textTheme.bodyLarge),
                    Text(appointment.location ?? '-', style: textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                    const SizedBox(height: 2),
                    Text('Description', style: compact ? textTheme.bodyMedium : textTheme.bodyLarge),
                    Text(
                      hasDescription ? appointment.description! : 'Pas de description',
                      style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
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

import 'package:flutter/material.dart';

import '../../viewmodels/appointment_view_model.dart';
import '../../widgets/agenda/appointment_form_widgets.dart';

class AppointmentFormView extends StatefulWidget {
  const AppointmentFormView({super.key});

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  late final AppointmentViewModel _viewModel;
  bool _showReminder = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AppointmentViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final compact = width < 360;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('Nouveau rendez-vous', style: textTheme.titleMedium),
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(compact ? 12 : 16, compact ? 10 : 12, compact ? 12 : 16, 110),
              children: [
                Text('Planifiez vos rendez-vous', style: compact ? textTheme.titleMedium : textTheme.titleLarge),
                SizedBox(height: compact ? 10 : 14),
                AppointmentSectionLabel(text: 'Nom du rendez-vous', compact: compact),
                AppointmentTextField(
                  controller: _viewModel.titleController,
                  hint: 'Ex : Consultation de routine',
                  compact: compact,
                ),
                SizedBox(height: compact ? 8 : 10),
                AppointmentSectionLabel(text: 'Date', compact: compact),
                AppointmentPickerField(
                  value: _viewModel.formattedDate,
                  placeholder: 'JJ/MM/AAAA',
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _viewModel.pickDate(context),
                  compact: compact,
                ),
                SizedBox(height: compact ? 8 : 10),
                AppointmentSectionLabel(text: 'Heure', compact: compact),
                AppointmentPickerField(
                  value: _viewModel.formattedTime,
                  placeholder: '--:-- --',
                  icon: Icons.access_time_outlined,
                  onTap: () => _viewModel.pickTime(context),
                  compact: compact,
                ),
                SizedBox(height: compact ? 8 : 10),
                AppointmentSectionLabel(text: 'Type de consultation', compact: compact),
                ConsultationTypeField(
                  value: _viewModel.consultationType,
                  options: _viewModel.consultationTypes,
                  onChanged: _viewModel.setConsultationType,
                  compact: compact,
                ),
                SizedBox(height: compact ? 8 : 10),
                AppointmentSectionLabel(text: 'Lieu', compact: compact),
                AppointmentTextField(
                  controller: _viewModel.locationController,
                  hint: 'Entrez une adresse ou un centre',
                  icon: Icons.location_on_outlined,
                  compact: compact,
                ),
                SizedBox(height: compact ? 10 : 12),
                ListTile(
                  dense: compact,
                  contentPadding: EdgeInsets.zero,
                  title: Text('Rappel (optionnel)', style: textTheme.titleMedium),
                  trailing: Icon(_showReminder ? Icons.expand_less : Icons.expand_more),
                  onTap: () => setState(() => _showReminder = !_showReminder),
                ),
                if (_showReminder)
                  ReminderCard(
                    enabled: _viewModel.notificationsEnabled,
                    onToggle: _viewModel.setNotificationsEnabled,
                    options: _viewModel.reminderOptions,
                    selected: _viewModel.reminderDelayLabel,
                    onSelect: _viewModel.setReminderDelay,
                    compact: compact,
                  ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: EdgeInsets.fromLTRB(compact ? 12 : 16, 8, compact ? 12 : 16, compact ? 8 : 12),
            child: SaveAppointmentButton(
              isSaving: _viewModel.isSaving,
              onPressed: _submit,
              compact: compact,
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final success = await _viewModel.saveAppointment();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rendez-vous enregistre le ${_viewModel.formattedDate} a ${_viewModel.formattedTime}')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.lastError ?? 'Une erreur est survenue')),
    );
  }
}

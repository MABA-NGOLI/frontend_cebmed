import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/appointment.dart';
import '../../viewmodels/appointment_view_model.dart';
import '../../widgets/agenda/appointment_form_widgets.dart';

class AppointmentFormView extends StatefulWidget {
  const AppointmentFormView({super.key, this.initialAppointment});

  final Appointment? initialAppointment;

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  late final AppointmentViewModel _viewModel;
  bool _showReminder = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AppointmentViewModel(initialAppointment: widget.initialAppointment);
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
            title: Text(
              _viewModel.isEditing ? 'Modifier rendez-vous' : 'Nouveau rendez-vous',
              style: textTheme.titleMedium,
            ),
          ),
          body: SafeArea(
            child: Scrollbar(
              thumbVisibility: true,
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
                  AppointmentSectionLabel(text: 'Heure de debut', compact: compact),
                  AppointmentPickerField(
                    value: _viewModel.formattedStartTime,
                    placeholder: '--:-- --',
                    icon: Icons.access_time_outlined,
                    onTap: () => _viewModel.pickStartTime(context),
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  AppointmentSectionLabel(text: 'Heure de fin', compact: compact),
                  AppointmentPickerField(
                    value: _viewModel.formattedEndTime,
                    placeholder: '--:-- --',
                    icon: Icons.access_time_outlined,
                    onTap: () => _viewModel.pickEndTime(context),
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
                  SizedBox(height: compact ? 8 : 10),
                  AppointmentSectionLabel(text: 'Description', compact: compact),
                  AppointmentTextField(
                    controller: _viewModel.descriptionController,
                    hint: 'Ex: consultation routine',
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
                      onToggle: _handleReminderToggle,
                      options: _viewModel.reminderOptions,
                      selected: _viewModel.reminderDelayLabel,
                      onSelect: _viewModel.setReminderDelay,
                      compact: compact,
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: EdgeInsets.fromLTRB(compact ? 12 : 16, 8, compact ? 12 : 16, compact ? 8 : 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_viewModel.isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _viewModel.isSaving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer le rendez-vous'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SaveAppointmentButton(
                  isSaving: _viewModel.isSaving,
                  onPressed: _submit,
                  label: _viewModel.isEditing ? 'Enregistrer les modifications' : 'Enregistrer le rendez-vous',
                  compact: compact,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleReminderToggle(bool value) async {
    if (!value) {
      _viewModel.setNotificationsEnabled(false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final globallyAllowed = prefs.getBool('notifications_enabled') ?? false;
    if (globallyAllowed) {
      _viewModel.setNotificationsEnabled(true);
      return;
    }

    if (!mounted) return;
    final goToProfile = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications desactivees'),
        content: const Text(
          'Autorisez d abord les notifications dans Profil pour activer les rappels de rendez-vous.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aller au profil'),
          ),
        ],
      ),
    );

    if (goToProfile == true && mounted) {
      Navigator.of(context).pop('open_profile');
    }
  }
  Future<void> _submit() async {
    final success = await _viewModel.saveAppointment();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _viewModel.isEditing
                ? 'Rendez-vous modifie'
                : 'Rendez-vous enregistre le ${_viewModel.formattedDate} de ${_viewModel.formattedStartTime} a ${_viewModel.formattedEndTime}',
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.lastError ?? 'Une erreur est survenue')),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: const Text('Confirmer la suppression de ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _viewModel.deleteAppointment();
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous supprime')),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_viewModel.lastError ?? 'Suppression impossible')),
    );
  }
}


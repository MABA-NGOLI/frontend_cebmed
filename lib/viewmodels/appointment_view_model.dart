import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AppointmentViewModel extends ChangeNotifier {
  AppointmentViewModel({Appointment? initialAppointment})
      : _editingAppointmentId = initialAppointment?.id {
    if (initialAppointment == null) {
      selectedDate = DateTime.now();
      selectedStartTime = TimeOfDay.fromDateTime(DateTime.now());
      selectedEndTime = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(minutes: 30)),
      );
      return;
    }

    titleController.text = initialAppointment.title;
    locationController.text = initialAppointment.location ?? '';
    descriptionController.text = initialAppointment.description ?? '';
    selectedDate = DateTime(
      initialAppointment.startTime.year,
      initialAppointment.startTime.month,
      initialAppointment.startTime.day,
    );
    selectedStartTime = TimeOfDay.fromDateTime(initialAppointment.startTime);
    selectedEndTime = TimeOfDay.fromDateTime(initialAppointment.endTime);
    notificationsEnabled = initialAppointment.notificationsEnabled;
    consultationType = initialAppointment.consultationType ?? 'NON_RENSEIGNE';
    reminderDelayLabel = _mapMinutesToReminderLabel(initialAppointment.reminderDelay);
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final int? _editingAppointmentId;

  late DateTime selectedDate;
  late TimeOfDay selectedStartTime;
  late TimeOfDay selectedEndTime;
  bool notificationsEnabled = true;
  String consultationType = 'NON_RENSEIGNE';
  String reminderDelayLabel = '1h avant';

  bool isSaving = false;
  String? lastError;

  bool get isEditing => _editingAppointmentId != null;

  final List<String> consultationTypes = const [
    'NON_RENSEIGNE',
    'PRESENTIAL',
    'VIDEO',
    'PHONE',
  ];

  final List<String> reminderOptions = const [
    '30 min avant',
    '1h avant',
    '1 jour avant',
  ];

  String get formattedDate =>
      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

  String get formattedStartTime =>
      '${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}';

  String get formattedEndTime =>
      '${selectedEndTime.hour.toString().padLeft(2, '0')}:${selectedEndTime.minute.toString().padLeft(2, '0')}';

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    selectedDate = picked;
    notifyListeners();
  }

  Future<void> pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime,
    );

    if (picked == null) {
      return;
    }

    selectedStartTime = picked;
    notifyListeners();
  }

  Future<void> pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedEndTime,
    );

    if (picked == null) {
      return;
    }

    selectedEndTime = picked;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void setConsultationType(String value) {
    consultationType = value;
    notifyListeners();
  }

  void setReminderDelay(String value) {
    reminderDelayLabel = value;
    notifyListeners();
  }

  DateTime get selectedStartDateTime => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedStartTime.hour,
        selectedStartTime.minute,
      );

  DateTime get selectedEndDateTime => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedEndTime.hour,
        selectedEndTime.minute,
      );

  bool validateRequiredFields() {
    return titleController.text.trim().isNotEmpty &&
        locationController.text.trim().isNotEmpty;
  }

  int _mapReminderDelayToMinutes() {
    switch (reminderDelayLabel) {
      case '30 min avant':
        return 30;
      case '1h avant':
        return 60;
      case '1 jour avant':
        return 1440;
      default:
        return 60;
    }
  }

  String _mapMinutesToReminderLabel(int? minutes) {
    switch (minutes) {
      case 30:
        return '30 min avant';
      case 60:
        return '1h avant';
      case 1440:
        return '1 jour avant';
      default:
        return '1h avant';
    }
  }

  Future<bool> saveAppointment() async {
    if (!validateRequiredFields()) {
      lastError = 'Nom et lieu sont obligatoires';
      notifyListeners();
      return false;
    }

    isSaving = true;
    lastError = null;
    notifyListeners();

    try {
      final start = selectedStartDateTime;
      final end = selectedEndDateTime;

      if (!end.isAfter(start)) {
        lastError = 'L heure de fin doit etre apres l heure de debut';
        isSaving = false;
        notifyListeners();
        return false;
      }

      if (isEditing) {
        final updated = await ApiService.updateAppointment(
          id: _editingAppointmentId!,
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          location: locationController.text.trim(),
          startTime: start,
          endTime: end,
          notificationsEnabled: notificationsEnabled,
          consultationType: consultationType == 'NON_RENSEIGNE' ? null : consultationType,
          reminderDelay: _mapReminderDelayToMinutes(),
        );
        await _syncReminderForAppointment(updated);
      } else {
        final created = await ApiService.createAppointment(
          title: titleController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
          location: locationController.text.trim(),
          startTime: start,
          endTime: end,
          notificationsEnabled: notificationsEnabled,
          consultationType: consultationType == 'NON_RENSEIGNE' ? null : consultationType,
          reminderDelay: _mapReminderDelayToMinutes(),
        );
        await _syncReminderForAppointment(created);
      }

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      final message = e.toString();
      if (message.contains('401') || message.toLowerCase().contains('unauthorized')) {
        lastError = 'Session expirée. Reconnecte-toi.';
      } else if (message.contains('403')) {
        lastError = 'Acces refuse pour cette action.';
      } else if (message.contains('400')) {
        lastError = 'Données invalides. Vérifie les champs.';
      } else if (message.contains('500')) {
        lastError = 'Erreur serveur. Reessaie dans un instant.';
      } else {
        lastError = isEditing
            ? 'Échec de modification du rendez-vous: $message'
            : 'Échec de création du rendez-vous: $message';
      }

      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment() async {
    if (_editingAppointmentId == null) {
      lastError = 'Aucun rendez-vous a supprimer';
      notifyListeners();
      return false;
    }

    isSaving = true;
    lastError = null;
    notifyListeners();

    try {
      await ApiService.deleteAppointment(_editingAppointmentId!);
      await NotificationService.cancelAppointmentReminder(_editingAppointmentId!);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = 'Échec de suppression du rendez-vous: $e';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _syncReminderForAppointment(Appointment appointment) async {
    if (!appointment.notificationsEnabled) {
      await NotificationService.cancelAppointmentReminder(appointment.id);
      return;
    }
    final delay = appointment.reminderDelay ?? _mapReminderDelayToMinutes();
    await NotificationService.scheduleAppointmentReminder(
      appointmentId: appointment.id,
      title: appointment.title,
      location: appointment.location,
      startAt: appointment.startTime,
      reminderDelayMinutes: delay,
    );
  }
}

import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AppointmentViewModel extends ChangeNotifier {
  AppointmentViewModel() {
    selectedDate = DateTime.now();
    selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  bool notificationsEnabled = true;
  String consultationType = 'PRESENTIAL';
  String reminderDelayLabel = '1h avant';

  bool isSaving = false;
  String? lastError;

  final List<String> consultationTypes = const [
    'Generaliste',
    'Cardiologue',
    'Dentiste',
    'Autre',
  ];

  final List<String> reminderOptions = const [
    '30 min avant',
    '1h avant',
    '1 jour avant',
  ];

  String get formattedDate =>
      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

  String get formattedTime =>
      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

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

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null) {
      return;
    }

    selectedTime = picked;
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

  DateTime get selectedDateTime => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
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
      final start = selectedDateTime;
      final end = start.add(const Duration(minutes: 30));

      await ApiService.createAppointment(
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        location: locationController.text.trim(),
        startTime: start,
        endTime: end,
        notificationsEnabled: notificationsEnabled,
        consultationType: consultationType,
        reminderDelay: _mapReminderDelayToMinutes(),
      );

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      final message = e.toString();
      if (message.contains('401') || message.toLowerCase().contains('unauthorized')) {
        lastError = 'Session expirée. Reconnecte-toi.';
      } else if (message.contains('403')) {
        lastError = 'Accès refusé pour cette action.';
      } else if (message.contains('400')) {
        lastError = 'Données invalides. Vérifie les champs.';
      } else if (message.contains('500')) {
        lastError = 'Erreur serveur. Réessaie dans un instant.';
      } else {
        lastError = 'Echec de création du rendez-vous: $message';
      }

      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void disposeControllers() {
    titleController.dispose();
    locationController.dispose();
    descriptionController.dispose();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }
}

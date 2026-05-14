import 'package:flutter/material.dart';

import 'package:frontend_cebmed/models/appointment.dart';
import 'package:frontend_cebmed/services/api_service.dart';

class AppointmentViewModel extends ChangeNotifier {
  AppointmentViewModel({Appointment? initialAppointment}) {
    final now = DateTime.now();
    final initialStart = initialAppointment?.startTime ?? now;
    final initialEnd = initialAppointment?.endTime ?? initialStart.add(const Duration(minutes: 30));

    selectedDate = initialStart;
    selectedTime = TimeOfDay.fromDateTime(initialStart);
    selectedEndTime = TimeOfDay.fromDateTime(initialEnd);

    editingAppointmentId = initialAppointment?.id;

    titleController.text = initialAppointment?.title ?? '';
    locationController.text = initialAppointment?.location ?? '';
    descriptionController.text = initialAppointment?.description ?? '';

    notificationsEnabled = initialAppointment?.notificationsEnabled ?? true;
    consultationType = _safeConsultationType(initialAppointment?.consultationType);
    reminderDelayLabel = _labelFromReminderDelay(initialAppointment?.reminderDelay);
  }

  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late TimeOfDay selectedEndTime;

  int? editingAppointmentId;

  bool notificationsEnabled = true;
  String consultationType = 'PRESENTIAL';
  String reminderDelayLabel = '1h avant';

  bool isSaving = false;
  String? lastError;

  bool get isEditing => editingAppointmentId != null;

  final List<String> consultationTypes = const [
    'PRESENTIAL',
    'VIDEO',
    'PHONE',
  ];

  final List<String> reminderOptions = const [
    '30 min avant',
    '1h avant',
    '1 jour avant',
  ];

  String _safeConsultationType(String? value) {
    if (consultationTypes.contains(value)) {
      return value!;
    }
    return 'PRESENTIAL';
  }

  String _labelFromReminderDelay(int? delay) {
    switch (delay) {
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

  String get formattedDate =>
      '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

  String get formattedTime =>
      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

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

  DateTime get selectedDateTime => DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
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
      final end = selectedEndDateTime;

      if (!end.isAfter(start)) {
        lastError = 'Heure de fin doit être après l\'heure de début';
        isSaving = false;
        notifyListeners();
        return false;
      }

      if (isEditing) {
        await ApiService.updateAppointment(
          id: editingAppointmentId!,
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
      } else {
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
      }

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = isEditing
          ? 'Echec de modification du rendez-vous'
          : 'Echec de creation du rendez-vous';
      isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAppointment() async {
    if (!isEditing) {
      return false;
    }

    isSaving = true;
    lastError = null;
    notifyListeners();

    try {
      await ApiService.deleteAppointment(editingAppointmentId!);
      isSaving = false;
      notifyListeners();
      return true;
    } catch (_) {
      lastError = 'Echec de suppression du rendez-vous';
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

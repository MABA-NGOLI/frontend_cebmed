import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/stock_model.dart';
import '../services/api_service.dart';

class StockAddViewModel extends ChangeNotifier {
  // --- Search & selection ---
  List<MedicationSearchResult> searchResults = const [];
  bool isSearching = false;
  MedicationSearchResult? selectedMedication;
  Timer? _debounce;

  // --- Submit ---
  bool isSubmitting = false;
  String? error;

  // --- Treatment ---
  bool isTreatment = false;
  List<int> selectedDays = const [];
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  bool hasEndDate = false;
  List<String> scheduleSlotTimes = const ['08:00'];

  // Search
  void onSearchChanged(String query) {
    _debounce?.cancel();
    if (selectedMedication != null && query.trim().isNotEmpty) {
      selectedMedication = null;
    }
    if (query.trim().length < 2) {
      searchResults = const [];
      notifyListeners();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _doSearch(query.trim()),
    );
  }

  Future<void> _doSearch(String name) async {
    isSearching = true;
    notifyListeners();
    try {
      searchResults = await ApiService.searchMedications(name);
    } catch (_) {
      searchResults = const [];
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  void selectMedication(MedicationSearchResult med) {
    selectedMedication = med;
    searchResults = const [];
    notifyListeners();
  }

  void clearSelection() {
    selectedMedication = null;
    isTreatment = false;
    notifyListeners();
  }

  // Treatment toggle
  void toggleTreatment(bool value) {
    isTreatment = value;
    notifyListeners();
  }

  // Days
  void toggleDay(int day) {
    final days = List<int>.from(selectedDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    selectedDays = days;
    notifyListeners();
  }

  // Dates
  void setStartDate(DateTime date) {
    startDate = date;
    notifyListeners();
  }

  void toggleHasEndDate(bool value) {
    hasEndDate = value;
    if (!value) endDate = null;
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    endDate = date;
    notifyListeners();
  }

  // Schedule slots
  void addScheduleSlot() {
    scheduleSlotTimes = [...scheduleSlotTimes, '08:00'];
    notifyListeners();
  }

  void removeScheduleSlot(int index) {
    if (scheduleSlotTimes.length <= 1) return;
    final list = List<String>.from(scheduleSlotTimes)..removeAt(index);
    scheduleSlotTimes = list;
    notifyListeners();
  }

  void updateSlotTime(int index, String time) {
    final list = List<String>.from(scheduleSlotTimes);
    list[index] = time;
    scheduleSlotTimes = list;
    notifyListeners();
  }

  // Derived
  String get frequency {
    if (selectedDays.isEmpty) return '';
    final set = selectedDays.toSet();
    if (set.length == 7) return 'Quotidien';
    if (set.length == 5 && set.containsAll({1, 2, 3, 4, 5})) return 'En semaine';
    const names = {0: 'Dim', 1: 'Lun', 2: 'Mar', 3: 'Mer', 4: 'Jeu', 5: 'Ven', 6: 'Sam'};
    const order = [1, 2, 3, 4, 5, 6, 0];
    return order.where((d) => set.contains(d)).map((d) => names[d]!).join(', ');
  }

  String get reminderText {
    if (selectedDays.isEmpty) return '';
    const fullNames = {
      0: 'Dimanche', 1: 'Lundi', 2: 'Mardi', 3: 'Mercredi',
      4: 'Jeudi', 5: 'Vendredi', 6: 'Samedi',
    };
    const order = [1, 2, 3, 4, 5, 6, 0];
    final names = order
        .where((d) => selectedDays.contains(d))
        .map((d) => fullNames[d]!)
        .join(', ');
    return 'Rappel programmé : $names';
  }

  // Submit
  Future<bool> createStock({
    required int quantity,
    required String location,
    List<double>? slotQuantities,
  }) async {
    if (selectedMedication == null) return false;

    if (isTreatment) {
      if (selectedDays.isEmpty) {
        error = 'Veuillez sélectionner au moins un jour';
        notifyListeners();
        return false;
      }
    }

    isSubmitting = true;
    error = null;
    notifyListeners();

    try {
      await ApiService.createStock(
        medicationId: selectedMedication!.id,
        quantity: quantity,
        location: location,
      );

      if (isTreatment) {
        final treatmentId = await ApiService.createTreatment(
          medicationId: selectedMedication!.id,
          frequency: frequency,
          daysOfWeek: selectedDays,
          startDate: _formatDate(startDate),
          endDate: hasEndDate && endDate != null ? _formatDate(endDate!) : null,
        );

        for (int i = 0; i < scheduleSlotTimes.length; i++) {
          final q =
              (slotQuantities != null && i < slotQuantities.length) ? slotQuantities[i] : 1.0;
          await ApiService.addTreatmentSchedule(
            treatmentId: treatmentId,
            timeOfDay: scheduleSlotTimes[i],
            quantity: q,
          );
        }
      }

      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

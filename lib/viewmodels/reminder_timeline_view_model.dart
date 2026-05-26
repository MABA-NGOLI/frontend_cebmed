import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/intake_model.dart';
import '../services/api_service.dart';

class ReminderEntry {
  const ReminderEntry({
    required this.intakeId,
    required this.medicationName,
    required this.scheduledAt,
    required this.status,
    required this.isPast,
    required this.isNext,
    required this.dosage,
    this.note,
  });

  final int intakeId;
  final String medicationName;
  final DateTime scheduledAt;
  final String status;
  final bool isPast;
  final bool isNext;
  final String dosage;
  final String? note;

  String get timeLabel {
    final local = scheduledAt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get isValidated => status == 'TAKEN';
  bool get isMissed => status == 'MISSED';
}

class ReminderTimelineViewModel extends ChangeNotifier {
  ReminderTimelineViewModel({DateTime? initialDay})
      : selectedDay = initialDay ?? DateTime.now(),
        focusedDay = initialDay ?? DateTime.now();

  DateTime selectedDay;
  DateTime focusedDay;
  List<ReminderEntry> entries = const [];
  bool isLoading = false;
  final Set<int> _locallyValidated = {};
  List<IntakeItem> _allIntakes = [];

  Future<void> initialize() => _load();

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final isToday = _sameDay(selectedDay, now);

      final treatments = await ApiService.getTreatments();
      debugPrint('[Reminders] ${treatments.length} traitement(s) chargé(s)');

      // Charge les intakes de chaque traitement en parallèle
      final intakeLists = await Future.wait(
        treatments.map((t) async {
          try {
            final list = await ApiService.getIntakesForTreatment(t.id);
            debugPrint('[Reminders] traitement ${t.id} → ${list.length} intake(s)');
            return list;
          } catch (e) {
            debugPrint('[Reminders] ERREUR traitement ${t.id}: $e');
            return <IntakeItem>[];
          }
        }),
      );

      final dayStart = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final allIntakes = intakeLists.expand((list) => list).toList();
      _allIntakes = allIntakes;
      debugPrint('[Reminders] total intakes bruts: ${allIntakes.length}');

      // Filtre sur le jour sélectionné
      final dayIntakes = allIntakes
          .where((i) =>
              i.scheduledAt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
              i.scheduledAt.isBefore(dayEnd))
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      debugPrint('[Reminders] intakes pour ${selectedDay.toIso8601String().substring(0, 10)}: ${dayIntakes.length}');

      // Détermine isPast / isNext
      // _locallyValidated garantit qu'une prise confirmée reste VALIDATED
      // même si l'API renvoie encore PENDING au prochain rechargement.
      bool markedNext = false;
      entries = dayIntakes.map((intake) {
        final effectivelyTaken =
            intake.isTaken || _locallyValidated.contains(intake.id);
        final effectiveStatus = _locallyValidated.contains(intake.id)
            ? 'TAKEN'
            : intake.status;

        final inPast = effectivelyTaken ||
            intake.isMissed ||
            (isToday && intake.scheduledAt.isBefore(now));

        bool isNext = false;
        if (isToday && !markedNext && !effectivelyTaken && !intake.isMissed &&
            !intake.scheduledAt.isBefore(now)) {
          isNext = true;
          markedNext = true;
        }

        return ReminderEntry(
          intakeId: intake.id,
          medicationName: intake.medicationName,
          scheduledAt: intake.scheduledAt,
          status: effectiveStatus,
          isPast: inPast,
          isNext: isNext,
          dosage: intake.treatment.dosage,
          note: intake.note,
        );
      }).toList();
    } catch (e) {
      debugPrint('[Reminders] ERREUR _load: $e');
      entries = const [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> validateEntry(int intakeId) async {
    await ApiService.validateIntake(intakeId);
    _locallyValidated.add(intakeId);
    await _load();
  }

  void selectDay(DateTime day) {
    selectedDay = day;
    focusedDay = day;
    _load();
  }

  void goPreviousWeek() {
    final prev = focusedDay.subtract(const Duration(days: 7));
    focusedDay = prev;
    selectedDay = prev;
    _load();
  }

  void goNextWeek() {
    final next = focusedDay.add(const Duration(days: 7));
    focusedDay = next;
    selectedDay = next;
    _load();
  }

  DateTime get weekStart => DateTime(
        focusedDay.year, focusedDay.month, focusedDay.day - focusedDay.weekday + 1);

  List<DateTime> get weekDays =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  /// Nombre de prises TAKEN sur la semaine affichée.
  int get weekTakenCount {
    final start = weekStart;
    final end = start.add(const Duration(days: 7));
    return _allIntakes.where((i) =>
        i.scheduledAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
        i.scheduledAt.isBefore(end) &&
        (i.isTaken || _locallyValidated.contains(i.id))).length;
  }

  /// Nombre total de prises sur la semaine affichée.
  int get weekTotalCount {
    final start = weekStart;
    final end = start.add(const Duration(days: 7));
    return _allIntakes.where((i) =>
        i.scheduledAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
        i.scheduledAt.isBefore(end)).length;
  }

  /// Retourne la couleur du dot pour un jour donné selon les statuts des intakes.
  /// null = aucun intake ce jour.
  Color? dotColorForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayIntakes = _allIntakes.where((i) =>
        i.scheduledAt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
        i.scheduledAt.isBefore(dayEnd)).toList();

    if (dayIntakes.isEmpty) return null;

    final statuses = dayIntakes.map((i) =>
        _locallyValidated.contains(i.id) ? 'TAKEN' : i.status);

    if (statuses.any((s) => s == 'MISSED')) return const Color(0xFFE57373);
    if (statuses.any((s) => s == 'PENDING')) return Colors.black26;
    return const Color(0xFF4CAF50);
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isSameDay(DateTime a, DateTime b) => _sameDay(a, b);
}

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/appointment.dart';
import '../models/intake_model.dart';
import '../services/api_service.dart';

class NextReminder {
  const NextReminder({
    required this.medicationName,
    required this.scheduledAt,
  });

  final String medicationName;
  final DateTime scheduledAt;

  String get timeLabel {
    final local = scheduledAt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String countdownFrom(DateTime now) {
    final diff = scheduledAt.difference(now).inMinutes;
    if (diff <= 0) return '';
    if (diff < 60) return 'Dans ${diff}min';
    final totalH = diff ~/ 60;
    if (totalH < 24) {
      final m = diff % 60;
      return m == 0 ? 'Dans ${totalH}h' : 'Dans ${totalH}h${m.toString().padLeft(2, '0')}';
    }
    final days = totalH ~/ 24;
    if (days == 1) return 'Demain';
    return 'Dans $days jours';
  }
}

class HomeViewModel extends ChangeNotifier {
  static const _storageCodeKey = 'caregiver_share_code';
  static const _storageCodeDateKey = 'caregiver_share_code_created_at';

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  String firstName = 'user';
  String shareCode = '------';
  bool isGeneratingCode = false;
  List<Appointment> appointments = const [];
  NextReminder? nextReminder;
  bool isLoadingReminder = true;
  Timer? _refreshCodeTimer;
  static const Duration _codeRefreshInterval = Duration(hours: 8);

  Future<void> initialize() async {
    _startAutoRefreshCode();
    await _loadCachedCode();
    await Future.wait([
      loadUser(),
      ensureFreshShareCode(),
      loadAppointments(),
      loadNextReminder(),
    ]);
  }

  Future<void> _loadCachedCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_storageCodeKey);
      if (cached != null && cached.trim().isNotEmpty) {
        shareCode = cached.trim();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _cacheCode(String code) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageCodeKey, code);
      await prefs.setString(_storageCodeDateKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<bool> _shouldRegenerateCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final createdAtRaw = prefs.getString(_storageCodeDateKey);
      final cachedCode = prefs.getString(_storageCodeKey);

      if (cachedCode == null || cachedCode.trim().isEmpty) {
        return true;
      }

      if (createdAtRaw == null || createdAtRaw.trim().isEmpty) {
        return true;
      }

      final createdAt = DateTime.tryParse(createdAtRaw);
      if (createdAt == null) {
        return true;
      }

      return DateTime.now().difference(createdAt) >= _codeRefreshInterval;
    } catch (_) {
      return true;
    }
  }

  Future<void> ensureFreshShareCode() async {
    await createShareCode();
  }

  Future<void> loadAppointments() async {
    try {
      appointments = await ApiService.getAppointments();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadNextReminder() async {
    isLoadingReminder = true;
    notifyListeners();
    try {
      final now = DateTime.now();

      final treatments = await ApiService.getTreatments();
      debugPrint('[Home] ${treatments.length} traitement(s) chargé(s)');

      final intakeLists = await Future.wait(
        treatments.map((t) async {
          try {
            final list = await ApiService.getIntakesForTreatment(t.id);
            debugPrint('[Home] traitement ${t.id} → ${list.length} intake(s)');
            return list;
          } catch (e) {
            debugPrint('[Home] ERREUR traitement ${t.id}: $e');
            return <IntakeItem>[];
          }
        }),
      );

      IntakeItem? best;
      for (final list in intakeLists) {
        for (final intake in list) {
          if (!intake.isPending) continue;
          if (intake.scheduledAt.isBefore(now)) continue;
          if (best == null || intake.scheduledAt.isBefore(best.scheduledAt)) {
            best = intake;
          }
        }
      }
      debugPrint('[Home] nextReminder: ${best?.id} (${best?.medicationName}) @ ${best?.scheduledAt}');
      nextReminder = best == null
          ? null
          : NextReminder(
              medicationName: best.medicationName,
              scheduledAt: best.scheduledAt,
            );
    } catch (e) {
      debugPrint('[Home] ERREUR loadNextReminder: $e');
      nextReminder = null;
    } finally {
      isLoadingReminder = false;
      notifyListeners();
    }
  }

  List<Appointment> appointmentsForDay(DateTime day) {
    return appointments.where((a) {
      return a.startTime.year == day.year &&
          a.startTime.month == day.month &&
          a.startTime.day == day.day;
    }).toList();
  }

  Future<void> loadUser() async {
    try {
      final me = await ApiService.getMe();
      firstName = me.user.firstName.trim().isEmpty ? 'user' : me.user.firstName.trim();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> createShareCode({bool force = false}) async {
    if (!force) {
      final regenerate = await _shouldRegenerateCode();
      if (!regenerate && shareCode.trim().isNotEmpty && shareCode != '------') {
        return;
      }
    }
    isGeneratingCode = true;
    notifyListeners();

    try {
      final code = await ApiService.createCaregiverInviteCode();
      shareCode = code;
      await _cacheCode(code);
    } catch (_) {
      // Keep the last valid code if refresh fails.
    } finally {
      isGeneratingCode = false;
      notifyListeners();
    }
  }

  void _startAutoRefreshCode() {
    _refreshCodeTimer?.cancel();
    _refreshCodeTimer = Timer.periodic(_codeRefreshInterval, (_) {
      createShareCode(force: true);
    });
  }

  Future<bool> shareCurrentCode() async {
    if (shareCode.trim().isEmpty || shareCode == '------') {
      await createShareCode();
      if (shareCode.trim().isEmpty || shareCode == '------') {
        return false;
      }
    }
    await SharePlus.instance.share(
      ShareParams(text: 'Mon code de partage CEBMED: $shareCode'),
    );
    return true;
  }

  String capitalize(String v) {
    if (v.isEmpty) return v;
    return v[0].toUpperCase() + v.substring(1);
  }

  DateTime weekStart(DateTime day) => DateTime(day.year, day.month, day.day - day.weekday + 1);
  DateTime weekEnd(DateTime day) => weekStart(day).add(const Duration(days: 6));

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay = selected;
    focusedDay = focused;
    notifyListeners();
  }

  void onPageChanged(DateTime focused) {
    focusedDay = focused;
    notifyListeners();
  }

  void goPreviousWeek() {
    final next = focusedDay.subtract(const Duration(days: 7));
    focusedDay = next;
    selectedDay = next;
    notifyListeners();
  }

  void goNextWeek() {
    final next = focusedDay.add(const Duration(days: 7));
    focusedDay = next;
    selectedDay = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshCodeTimer?.cancel();
    super.dispose();
  }
}

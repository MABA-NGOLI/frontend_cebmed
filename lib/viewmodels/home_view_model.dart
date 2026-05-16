import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/appointment.dart';
import '../services/api_service.dart';

class HomeViewModel extends ChangeNotifier {
  static const _storageCodeKey = 'caregiver_share_code';
  static const _storageCodeDateKey = 'caregiver_share_code_created_at';

  DateTime focusedDay = DateTime.now();
  DateTime selectedDay = DateTime.now();
  String firstName = 'user';
  String shareCode = '------';
  bool isGeneratingCode = false;
  List<Appointment> appointments = const [];
  Timer? _refreshCodeTimer;
  static const Duration _codeRefreshInterval = Duration(hours: 8);

  Future<void> initialize() async {
    _startAutoRefreshCode();
    await _loadCachedCode();
    await Future.wait([
      loadUser(),
      ensureFreshShareCode(),
      loadAppointments(),
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
    final regenerate = await _shouldRegenerateCode();
    if (regenerate) {
      await createShareCode();
      return;
    }
  }

  Future<void> loadAppointments() async {
    try {
      appointments = await ApiService.getAppointments();
      notifyListeners();
    } catch (_) {}
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

  Future<void> createShareCode() async {
    isGeneratingCode = true;
    notifyListeners();

    try {
      final code = await ApiService.createCaregiverInviteCode();
      shareCode = code;
      await _cacheCode(code);
    } catch (_) {
      shareCode = '------';
    } finally {
      isGeneratingCode = false;
      notifyListeners();
    }
  }

  void _startAutoRefreshCode() {
    _refreshCodeTimer?.cancel();
    _refreshCodeTimer = Timer.periodic(_codeRefreshInterval, (_) {
      createShareCode();
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


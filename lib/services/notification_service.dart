import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);

    // ── FCM ──────────────────────────────────────────────
    await _initFCM();
  }

  // ── FCM ───────────────────────────────────────────────
  static Future<void> _initFCM() async {
    final messaging = FirebaseMessaging.instance;

    // Demande permission (surtout iOS)
    await messaging.requestPermission();

    // Si le token se renouvelle (l'envoi initial se fait via syncFcmToken après login)
    messaging.onTokenRefresh.listen(_sendTokenToBackend);

    // Notif reçue en foreground → affiche une notif locale
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(
          title: notification.title ?? 'CebMed',
          body: notification.body ?? '',
        );
      }
    });
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final url = '${ApiService.baseUrl}/notifications/fcm-token';
      final hdrs = ApiService.headers();
      debugPrint('[FCM] POST $url');
      debugPrint('[FCM] Authorization present: ${hdrs.containsKey("Authorization")}');
      final response = await http.post(
        Uri.parse(url),
        headers: hdrs,
        body: jsonEncode({'token': token}),
      );
      debugPrint('[FCM] response: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('[FCM] _sendTokenToBackend failed: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'Notifications push',
      channelDescription: 'Notifications reçues via FCM',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  // ── Permissions ───────────────────────────────────────
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  // ── Rappels RDV (inchangé) ────────────────────────────
  static int _appointmentNotificationId(int appointmentId) =>
      1000000 + appointmentId;

  static Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String title,
    required String? location,
    required DateTime startAt,
    required int reminderDelayMinutes,
  }) async {
    final scheduledAt =
        startAt.subtract(Duration(minutes: reminderDelayMinutes));
    if (!scheduledAt.isAfter(DateTime.now())) {
      await cancelAppointmentReminder(appointmentId);
      return;
    }

    final body = (location == null || location.trim().isEmpty)
        ? 'Votre rendez-vous commence bientot.'
        : 'Lieu: ${location.trim()}';

    const androidDetails = AndroidNotificationDetails(
      'appointments_channel',
      'Rendez-vous',
      channelDescription: 'Rappels des rendez-vous CebMed',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id: _appointmentNotificationId(appointmentId),
      title: 'Rappel: $title',
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> syncFcmToken() async {
    try {
      debugPrint('[FCM] syncFcmToken: start, Firebase apps: ${Firebase.apps.map((a) => a.name).toList()}');
      if (Firebase.apps.isEmpty) {
        debugPrint('[FCM] Firebase not ready, re-initializing...');
        await Firebase.initializeApp();
      }
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[FCM] syncFcmToken: token=${token == null ? "NULL" : "${token.substring(0, 20)}..."}');
      if (token != null) {
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('[FCM] syncFcmToken failed: $e');
    }
  }

  static Future<void> cancelAppointmentReminder(int appointmentId) async {
    await _plugin.cancel(id: _appointmentNotificationId(appointmentId));
  }
}
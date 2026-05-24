import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
  }

  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  static int _appointmentNotificationId(int appointmentId) => 1000000 + appointmentId;

  static Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String title,
    required String? location,
    required DateTime startAt,
    required int reminderDelayMinutes,
  }) async {
    final scheduledAt = startAt.subtract(Duration(minutes: reminderDelayMinutes));
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

  static Future<void> cancelAppointmentReminder(int appointmentId) async {
    await _plugin.cancel(id: _appointmentNotificationId(appointmentId));
  }
}

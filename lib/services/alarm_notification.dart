import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const String alarmStopActionId = 'stop';

const String alarmSnoozeActionId = 'snooze';

class AlarmNotification {
  AlarmNotification._();

  static final instance = AlarmNotification._();

  final FlutterLocalNotificationsPlugin localNotif =
      FlutterLocalNotificationsPlugin();

  static final StreamController<String?> selectNotificationStream =
      StreamController<String?>.broadcast();

  /// Adds configuration for local notifications and initialize service.
  Future<void> init() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await localNotif.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationStream.add(notificationResponse.id.toString());
            selectNotificationStream.add(notificationResponse.payload);
            break;
          case NotificationResponseType.selectedNotificationAction:
            selectNotificationStream.add(notificationResponse.id.toString());
            selectNotificationStream.add(notificationResponse.actionId);

            break;
        }
      },
    );
    tz.initializeTimeZones();
  }

  /// Shows notification permission request.
  Future<bool> requestPermission() async {
    late bool? result;

    if (Platform.isAndroid) {
      result = await localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
    } else {
      result = await localNotif
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
    return result ?? false;
  }

  tz.TZDateTime nextInstanceOfTime(Time time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
        time.second,
      ),
      tz.local,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules notification at the given time.
  Future<void> scheduleAlarmNotif({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentSound: false,
      presentAlert: false,
      presentBadge: false,
    );

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm',
      'alarm_package',
      channelDescription: 'Alarm package',
      importance: Importance.max,
      priority: Priority.max,
      enableLights: true,
      fullScreenIntent: true,
      playSound: false,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(alarmStopActionId, 'Stop',
            showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction(alarmSnoozeActionId, 'Snooze',
            showsUserInterface: true, cancelNotification: true),
      ],
    );

    const platformChannelSpecifics = NotificationDetails(
      iOS: iOSPlatformChannelSpecifics,
      android: androidPlatformChannelSpecifics,
    );

    final zdt = nextInstanceOfTime(
      Time(
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
      ),
    );

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      debugPrint('[Alarm] Notification permission not granted');
      return;
    }

    try {
      await localNotif.zonedSchedule(
        id,
        title,
        body,
        zdt,
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint(
          '[Alarm] Notification with id $id scheduled successfuly at $zdt');
    } catch (e) {
      debugPrint('[Alarm] Schedule notification with id $id error: $e');
    }
  }

  /// Cancels notification. Called when the alarm is cancelled or
  /// when an alarm is overriden.
  Future<void> cancel(int id) async {
    await localNotif.cancel(id);
    debugPrint('[Alarm] Notification with id $id canceled');
  }
}

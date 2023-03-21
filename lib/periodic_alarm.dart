import 'dart:async';
import 'dart:io';

import 'package:periodic_alarm/model/alarms_model.dart';
import 'package:periodic_alarm/services/alarm_notification.dart';
import 'package:periodic_alarm/services/alarm_storage.dart';
import 'package:periodic_alarm/src/android_alarm.dart';

class PeriodicAlarm {
  /// Whether it's iOS device.
  static bool get iOS => Platform.isIOS;

  /// Whether it's Android device.
  static bool get android => Platform.isAndroid;

  static final ringStream = StreamController<AlarmModel>();

  static Future<void> init() async {
    await Future.wait([
      if (android) AndroidAlarm.init(),
      AlarmNotification.instance.init(),
      AlarmStorage.init(),
    ]);
  }

  static Future<bool> setOneAlarm({required AlarmModel alarmModel}) async {
    // for (final alarm in PeriodicAlarm.getAlarms()) {
    //   if (alarm.id == alarmModel.id ||
    //       (alarm.dateTime.day == alarmModel.dateTime.day &&
    //           alarm.dateTime.hour == alarmModel.dateTime.hour &&
    //           alarm.dateTime.minute == alarmModel.dateTime.minute)) {
    //     await PeriodicAlarm.stop(alarm.id);
    //   }
    // }

    await AlarmStorage.saveAlarm(alarmModel);
    //await AlarmNotification.instance.cancel(alarmModel.id);

    if (alarmModel.enableNotificationOnKill) {
      await AlarmNotification.instance.requestPermission();
    }

    return await AndroidAlarm.setOneAlarm(
      alarmModel.id,
      alarmModel.dateTime,
      () => ringStream.add(alarmModel),
      alarmModel.assetAudioPath,
      alarmModel.loopAudio,
      alarmModel.fadeDuration,
      alarmModel.notificationTitle,
      alarmModel.notificationBody,
      alarmModel.enableNotificationOnKill,
    );
  }

  static Future<bool> setPeriodicAlarm({required AlarmModel alarmModel}) async {
    await AlarmStorage.saveAlarm(alarmModel);
    //await AlarmNotification.instance.cancel(alarmModel.id);

    if (alarmModel.enableNotificationOnKill) {
      await AlarmNotification.instance.requestPermission();
    }

    return await AndroidAlarm.setPeriodicAlarm(
        alarmModel.id,
        alarmModel.dateTime,
        () => ringStream.add(alarmModel),
        alarmModel.assetAudioPath,
        alarmModel.loopAudio,
        alarmModel.fadeDuration,
        alarmModel.notificationTitle,
        alarmModel.notificationBody,
        alarmModel.enableNotificationOnKill,
        alarmModel.monday,
        alarmModel.tuesday,
        alarmModel.wednesday,
        alarmModel.thursday,
        alarmModel.friday,
        alarmModel.saturday,
        alarmModel.sunday,
        alarmModel.active);
  }

  static Future<bool> stop() async {
    //await AlarmStorage.unsaveAlarm(id);

    //AlarmNotification.instance.cancel(id);

    return await AndroidAlarm.stop();
  }

  static Future<bool> cancelAlarm(int alarmId) async {
    bool isCanceledAlarm = await AndroidAlarm.cancelAlarm(alarmId);

    return isCanceledAlarm;
  }

  static Future<bool> deleteAlarm(int alarmId) async {
    bool isDeletedAlarm = await AlarmStorage.deleteAlarm(alarmId);

    return isDeletedAlarm;
  }

  static Future<bool> saveActiveAlarmStatu(int id, bool active) async {
    bool res = await AlarmStorage.alarmActiveChange(id, active);

    return res;
  }

  static Future<void> setNotificationOnAppKillContent(
    String title,
    String body,
  ) =>
      AlarmStorage.setNotificationContentOnAppKill(title, body);

  static bool hasAlarm() => AlarmStorage.hasAlarm();

  static List<AlarmModel> getAlarms() => AlarmStorage.getSavedAlarms();

  static AlarmModel getAlarmWithId(int alarmId) =>
      AlarmStorage.getAlarm(alarmId);
}

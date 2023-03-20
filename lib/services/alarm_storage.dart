import 'dart:convert';

import 'package:periodic_alarm/model/alarms_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const prefix = '__alarm_id__';
const notificationOnAppKill = 'notificationOnAppKill';
const notificationOnAppKillTitle = 'notificationOnAppKillTitle';
const notificationOnAppKillBody = 'notificationOnAppKillBody';

class AlarmStorage {
  static late SharedPreferences prefs;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }

  /// Saves alarm info in local storage so we can restore it later
  /// in the case app is terminated.
  static Future<void> saveAlarm(AlarmModel alarmModel) => prefs.setString(
        '$prefix${alarmModel.id}',
        json.encode(alarmModel.toJson()),
      );

  /// Removes alarm from local storage.
  static Future<void> unsaveAlarm(int id) => prefs.remove("$prefix$id");

  /// Wether at least one alarm is set.
  static bool hasAlarm() {
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(prefix)) return true;
    }
    return false;
  }

  /// Returns all alarms info from local storage in the case app is terminated
  /// and we need to restore previously scheduled alarms.
  static List<AlarmModel> getSavedAlarms() {
    final alarms = <AlarmModel>[];
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(prefix)) {
        final res = prefs.getString(key);
        alarms.add(AlarmModel.fromJson(json.decode(res!)));
      }
    }
    return alarms;
  }

  static Future<bool> deleteAlarm(int alarmId) async{
    bool isDeletedAlarm = await prefs.remove("$prefix$alarmId");

    return isDeletedAlarm;
  }

  static AlarmModel getAlarm(int alarmId){
    final alarm = prefs.getString("$prefix$alarmId");

    AlarmModel alarmModel = AlarmModel.fromJson(json.decode(alarm!));
    
    return alarmModel;
  }

  /// Saves on app kill notification custom title and body.
  static Future<void> setNotificationContentOnAppKill(
    String title,
    String body,
  ) =>
      Future.wait([
        prefs.setString(notificationOnAppKillTitle, title),
        prefs.setString(notificationOnAppKillBody, body),
      ]);

  /// Returns notification on app kill title.
  static String getNotificationOnAppKillTitle() =>
      prefs.getString(notificationOnAppKillTitle) ?? 'Your alarms may not ring';

  /// Returns notification on app kill body.
  static String getNotificationOnAppKillBody() =>
      prefs.getString(notificationOnAppKillBody) ??
      'You killed the app. Please reopen so your alarms can be rescheduled.';
}

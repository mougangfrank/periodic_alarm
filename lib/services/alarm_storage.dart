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

  static Future<bool> alarmActiveChange(int id, bool active) async {
    var alarmString = prefs.getString("$prefix$id");

    var alarmModel = AlarmModel.fromJson(json.decode(alarmString!));

    alarmModel.setActive = active;

    bool res =
        await prefs.setString("$prefix$id", json.encode(alarmModel.toJson()));

    return res;
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

  static Future<int> getSavedAlarmsNumber() async {
    final alarmsKey = <int>[];
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final keys = prefs.getKeys();

    for (var key in keys) {
      if (key.startsWith(prefix)) {
        
        var id = key.replaceAll(prefix, '');
        alarmsKey.add(int.parse(id));
      }
    }
    alarmsKey.sort();

    return alarmsKey.last;
  }

  static Future<bool> deleteAlarm(int alarmId) async {
    bool isDeletedAlarm = await prefs.remove("$prefix$alarmId");

    return isDeletedAlarm;
  }

  static Future<void> saveIsAlarmRinging(int id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    prefs.setInt('isRinging', id);
  }

  static Future<bool> removeAlarmRinging() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    bool isRemove = await prefs.remove('isRinging');
    return isRemove;
  }

  static Future<int?> getAlarmRinging() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.reload();
    return prefs.getInt('isRinging');
  }

  static AlarmModel? getAlarm(int alarmId) {
    final alarm = prefs.getString("$prefix$alarmId");

    if (alarm == null) {
      return null;
    }

    AlarmModel? alarmModel = AlarmModel.fromJson(json.decode(alarm));

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

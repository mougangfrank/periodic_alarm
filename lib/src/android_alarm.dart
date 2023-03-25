import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'package:periodic_alarm/services/alarm_notification.dart';
import 'package:periodic_alarm/services/alarm_storage.dart';

class AndroidAlarm {
  static String ringPort = 'alarm-ring';
  static String stopPort = 'alarm-stop';

  /// Initializes AndroidAlarmManager dependency
  static Future<void> init() => AndroidAlarmManager.initialize();

  static const platform =
      MethodChannel('com.cagridurmus.periodic_alarm/notifOnAppKill');

  static bool get hasAnotherAlarm => AlarmStorage.getSavedAlarms().length > 1;

  static Future<bool> setOneAlarm(
      AlarmModel alarmModel, void Function()? onRing) async {
    try {
      final ReceivePort port = ReceivePort();
      final success = IsolateNameServer.registerPortWithName(
        port.sendPort,
        "$ringPort-${alarmModel.id}",
      );

      if (!success) {
        IsolateNameServer.removePortNameMapping("$ringPort-${alarmModel.id}");
        IsolateNameServer.registerPortWithName(
            port.sendPort, "$ringPort-${alarmModel.id}");
      }
      port.listen((message) {
        debugPrint('[Alarm] $message');
        if (message == 'ring') onRing?.call();
      });
    } catch (e) {
      debugPrint('[Alarm] ReceivePort error: $e');
      return false;
    }

    if (alarmModel.enableNotificationOnKill && !hasAnotherAlarm) {
      try {
        await platform.invokeMethod(
          'setNotificationOnKillService',
          {
            'title': AlarmStorage.getNotificationOnAppKillTitle(),
            'description': AlarmStorage.getNotificationOnAppKillBody(),
          },
        );
        debugPrint('[Alarm] NotificationOnKillService set with success');
      } catch (e) {
        debugPrint('[Alarm] NotificationOnKillService error: $e');
      }
    }
    final res = await AndroidAlarmManager.oneShotAt(
        alarmModel.dateTime, alarmModel.id, AndroidAlarm.playAlarm,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        rescheduleOnReboot: true,
        params: alarmModel.toJson());

    debugPrint(res
        ? '${alarmModel.dateTime} ve ${alarmModel.id} li tek seferlik alarm oluşturuldu.'
        : 'Oluşturulamadı');

    if (res &&
        alarmModel.notificationTitle != null &&
        alarmModel.notificationTitle!.isNotEmpty &&
        alarmModel.notificationBody != null &&
        alarmModel.notificationBody!.isNotEmpty &&
        alarmModel.active) {
      await AlarmNotification.instance.scheduleAlarmNotif(
        id: alarmModel.id,
        dateTime: alarmModel.dateTime,
        title: alarmModel.notificationTitle!,
        body: alarmModel.notificationBody!,
      );
    }
    return res;
  }

  static Future<bool> setPeriodicAlarm(
      AlarmModel alarmModel, void Function()? onRing) async {
    try {
      final ReceivePort port = ReceivePort();
      final success = IsolateNameServer.registerPortWithName(
        port.sendPort,
        "$ringPort-${alarmModel.id}",
      );

      if (!success) {
        IsolateNameServer.removePortNameMapping("$ringPort-${alarmModel.id}");
        IsolateNameServer.registerPortWithName(
            port.sendPort, "$ringPort-${alarmModel.id}");
      }
      port.listen((message) {
        debugPrint('[Alarm] $message');
        if (message == 'ring') onRing?.call();
      });
    } catch (e) {
      debugPrint('[Alarm] ReceivePort error: $e');
      return false;
    }

    if (alarmModel.enableNotificationOnKill && !hasAnotherAlarm) {
      try {
        await platform.invokeMethod(
          'setNotificationOnKillService',
          {
            'title': AlarmStorage.getNotificationOnAppKillTitle(),
            'description': AlarmStorage.getNotificationOnAppKillBody(),
          },
        );
        debugPrint('[Alarm] NotificationOnKillService set with success');
      } catch (e) {
        debugPrint('[Alarm] NotificationOnKillService error: $e');
      }
    }

    final res = await AndroidAlarmManager.oneShotAt(
        alarmModel.dateTime, alarmModel.id, AndroidAlarm.playAlarm1,
        alarmClock: true,
        allowWhileIdle: true,
        exact: true,
        rescheduleOnReboot: true,
        params: alarmModel.toJson());

    debugPrint(res
        ? '${alarmModel.dateTime} ve ${alarmModel.id} li periodic alarm oluşturuldu.'
        : 'Oluşturulamadı');

    if (res &&
        alarmModel.notificationTitle != null &&
        alarmModel.notificationTitle!.isNotEmpty &&
        alarmModel.notificationBody != null &&
        alarmModel.notificationBody!.isNotEmpty &&
        alarmModel.active &&
        alarmModel.days[DateTime.now().weekday - 1]) {
      await AlarmNotification.instance.scheduleAlarmNotif(
        id: alarmModel.id,
        dateTime: alarmModel.dateTime,
        title: alarmModel.notificationTitle!,
        body: alarmModel.notificationBody!,
      );
    }
    return res;
  }

  @pragma('vm:entry-point')
  static Future<void> playAlarm(int id, Map<String, dynamic> data) async {
    var alarmModel = AlarmModel.fromJson(data);
    SendPort send = IsolateNameServer.lookupPortByName("$ringPort-$id")!;

    send.send('ring');
    if (alarmModel.active) {
      final audioPlayer = AudioPlayer();

      try {
        final assetAudioPath = alarmModel.assetAudioPath;

        if (assetAudioPath.startsWith('http')) {
          await audioPlayer.setUrl(assetAudioPath);
        } else {
          await audioPlayer.setAsset(assetAudioPath);
        }

        final loopAudio = alarmModel.loopAudio;
        if (loopAudio) audioPlayer.setLoopMode(LoopMode.all);

        send.send('Alarm fadeDuration: ${data.toString()}');

        final fadeDuration = (alarmModel.fadeDuration).toDouble();

        if (fadeDuration > 0.0) {
          int counter = 0;

          audioPlayer.setVolume(0.1);
          audioPlayer.play();

          send.send('Alarm playing with fadeDuration ${fadeDuration}s');

          Timer.periodic(
            Duration(milliseconds: fadeDuration * 1000 ~/ 10),
            (timer) {
              counter++;
              audioPlayer.setVolume(counter / 10);
              if (counter >= 10) timer.cancel();
            },
          );
        } else {
          audioPlayer.play();
          send.send('Alarm with id $id starts playing.');
        }
      } catch (e) {
        send.send('AudioPlayer with id $id error: ${e.toString()}');
        await AudioPlayer.clearAssetCache();
        send.send('Asset cache reset. Please try again.');
      }

      try {
        final ReceivePort port = ReceivePort();
        final success =
            IsolateNameServer.registerPortWithName(port.sendPort, stopPort);

        if (!success) {
          IsolateNameServer.removePortNameMapping(stopPort);
          IsolateNameServer.registerPortWithName(port.sendPort, stopPort);
        }

        port.listen(
          (message) async {
            send.send('(isolate) received: $message');
            if (message == 'stop') {
              await audioPlayer.stop();
              await audioPlayer.dispose();
              port.close();
            }
          },
        );
      } catch (e) {
        send.send('(isolate) ReceivePort error: $e');
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> playAlarm1(int id, Map<String, dynamic> data) async {
    var now = DateTime.now();

    var alarmModel = AlarmModel.fromJson(data);
    SendPort send = IsolateNameServer.lookupPortByName("$ringPort-$id")!;

    send.send('ring');

    if (alarmModel.days[now.weekday - 1] && alarmModel.active) {
      final audioPlayer = AudioPlayer();

      try {
        final assetAudioPath = alarmModel.assetAudioPath;

        if (assetAudioPath.startsWith('http')) {
          await audioPlayer.setUrl(assetAudioPath);
        } else {
          await audioPlayer.setAsset(assetAudioPath);
        }

        final loopAudio = alarmModel.loopAudio;
        if (loopAudio) audioPlayer.setLoopMode(LoopMode.all);

        send.send('Alarm fadeDuration: ${alarmModel.fadeDuration.toString()}');

        final fadeDuration = (alarmModel.fadeDuration).toDouble();

        if (fadeDuration > 0.0) {
          int counter = 0;

          audioPlayer.setVolume(0.1);
          audioPlayer.play();

          send.send('Alarm playing with fadeDuration ${fadeDuration}s');

          Timer.periodic(
            Duration(milliseconds: fadeDuration * 1000 ~/ 10),
            (timer) {
              counter++;
              audioPlayer.setVolume(counter / 10);
              if (counter >= 10) timer.cancel();
            },
          );
        } else {
          audioPlayer.play();
          send.send('Alarm with id $id starts playing.');
        }
      } catch (e) {
        send.send('AudioPlayer with id $id error: ${e.toString()}');
        await AudioPlayer.clearAssetCache();
        send.send('Asset cache reset. Please try again.');
      }

      try {
        final ReceivePort port = ReceivePort();
        final success =
            IsolateNameServer.registerPortWithName(port.sendPort, stopPort);

        if (!success) {
          IsolateNameServer.removePortNameMapping(stopPort);
          IsolateNameServer.registerPortWithName(port.sendPort, stopPort);
        }

        port.listen(
          (message) async {
            send.send('(isolate) received: $message');
            if (message == 'stop') {
              await audioPlayer.stop();
              await audioPlayer.dispose();
              port.close();
            }
          },
        );
      } catch (e) {
        send.send('(isolate) ReceivePort error: $e');
      }
    }
  }

  static Future<bool> cancelAlarm(int alarmId) async {
    bool res = await AndroidAlarmManager.cancel(alarmId);

    return res;
  }

  @pragma('vm:entry-point')
  static Future<bool> stop() async {
    bool res;
    try {
      final SendPort send = IsolateNameServer.lookupPortByName(stopPort)!;
      send.send('stop');
      res = true;
    } catch (e) {
      debugPrint('[Alarm] (main) SendPort error: $e');
      res = false;
    }

    // if (!hasAnotherAlarm) stopNotificationOnKillService();
    return res;
  }

  static Future<void> stopNotificationOnKillService() async {
    try {
      await platform.invokeMethod('stopNotificationOnKillService');
      debugPrint('[Alarm] NotificationOnKillService stopped with success');
    } catch (e) {
      debugPrint('[Alarm] NotificationOnKillService error: $e');
    }
  }
}

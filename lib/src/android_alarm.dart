import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:periodic_alarm/services/alarm_notification.dart';
import 'package:periodic_alarm/services/alarm_storage.dart';

class AndroidAlarm {
  static String ringPort = 'alarm-ring';
  static String stopPort = 'alarm-stop';

  /// Initializes AndroidAlarmManager dependency
  static Future<void> init() => AndroidAlarmManager.initialize();

  static const platform = MethodChannel('com.cagridurmus.periodic_alarm/notifOnAppKill');

  static bool get hasAnotherAlarm => AlarmStorage.getSavedAlarms().length > 1;

  static Future<bool> setOneAlarm(
    int id,
    DateTime dateTime,
    void Function()? onRing,
    String assetAudioPath,
    bool loopAudio,
    double fadeDuration,
    String? notificationTitle,
    String? notificationBody,
    bool enableNotificationOnKill,
  ) async {
    try {
      final ReceivePort port = ReceivePort();
      final success = IsolateNameServer.registerPortWithName(
        port.sendPort,
        "$ringPort-$id",
      );

      if (!success) {
        IsolateNameServer.removePortNameMapping("$ringPort-$id");
        IsolateNameServer.registerPortWithName(port.sendPort, "$ringPort-$id");
      }
      port.listen((message) {
        debugPrint('[Alarm] $message');
        if (message == 'ring') onRing?.call();
      });
    } catch (e) {
      debugPrint('[Alarm] ReceivePort error: $e');
      return false;
    }

    if (enableNotificationOnKill && !hasAnotherAlarm) {
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
      dateTime,
      id,
      AndroidAlarm.playAlarm,
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      rescheduleOnReboot: true,
      params: {
        'assetAudioPath': assetAudioPath,
        'loopAudio': loopAudio,
        'fadeDuration': fadeDuration,
      },
    );

    if (res &&
        notificationTitle != null &&
        notificationTitle.isNotEmpty &&
        notificationBody != null &&
        notificationBody.isNotEmpty) {
      await AlarmNotification.instance.scheduleAlarmNotif(
        id: id,
        dateTime: dateTime,
        title: notificationTitle,
        body: notificationBody,
      );
    }
    return res;
  }

  static Future<bool> setPeriodicAlarm(
      int id,
      DateTime dateTime,
      void Function()? onRing,
      String assetAudioPath,
      bool loopAudio,
      double fadeDuration,
      String? notificationTitle,
      String? notificationBody,
      bool enableNotificationOnKill,
      bool monday,
      bool tuesday,
      bool wednesday,
      bool thursday,
      bool friday,
      bool saturday,
      bool sunday) async {
    try {
      final ReceivePort port = ReceivePort();
      final success = IsolateNameServer.registerPortWithName(
        port.sendPort,
        "$ringPort-$id",
      );

      if (!success) {
        IsolateNameServer.removePortNameMapping("$ringPort-$id");
        IsolateNameServer.registerPortWithName(port.sendPort, "$ringPort-$id");
      }
      port.listen((message) {
        debugPrint('[Alarm] $message');
        if (message == 'ring') onRing?.call();
      });
    } catch (e) {
      debugPrint('[Alarm] ReceivePort error: $e');
      return false;
    }

    if (enableNotificationOnKill && !hasAnotherAlarm) {
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
      dateTime,
      id,
      AndroidAlarm.playAlarm1,
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      rescheduleOnReboot: true,
      params: {
        'assetAudioPath': assetAudioPath,
        'loopAudio': loopAudio,
        'fadeDuration': fadeDuration,
        'monday': monday,
        'tuesday': tuesday,
        'wednesday': wednesday,
        'thursday': thursday,
        'friday': friday,
        'saturday': saturday,
        'sunday': sunday
      },
    );

    if (res &&
        notificationTitle != null &&
        notificationTitle.isNotEmpty &&
        notificationBody != null &&
        notificationBody.isNotEmpty) {
      await AlarmNotification.instance.scheduleAlarmNotif(
        id: id,
        dateTime: dateTime,
        title: notificationTitle,
        body: notificationBody,
      );
    }
    return res;
  }

  @pragma('vm:entry-point')
  static Future<void> playAlarm(int id, Map<String, dynamic> data) async {
    final audioPlayer = AudioPlayer();
    SendPort send = IsolateNameServer.lookupPortByName("$ringPort-$id")!;

    send.send('ring');

    try {
      final assetAudioPath = data['assetAudioPath'] as String;

      if (assetAudioPath.startsWith('http')) {
        await audioPlayer.setUrl(assetAudioPath);
      } else {
        await audioPlayer.setAsset(assetAudioPath);
      }

      final loopAudio = data['loopAudio'];
      if (loopAudio) audioPlayer.setLoopMode(LoopMode.all);

      send.send('Alarm fadeDuration: ${data.toString()}');

      final fadeDuration = (data['fadeDuration'] as int).toDouble();

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

  @pragma('vm:entry-point')
  static Future<void> playAlarm1(int id, Map<String, dynamic> data) async {
    var now = DateTime.now();

    final res = await AndroidAlarmManager.oneShotAt(
      now.add(Duration(days: 1)),
      id,
      AndroidAlarm.playAlarm1,
      alarmClock: true,
      allowWhileIdle: true,
      exact: true,
      rescheduleOnReboot: true,
      params: {
        'assetAudioPath': data['assetAudioPath'],
        'loopAudio': data['loopAudio'],
        'fadeDuration': data['fadeDuration'],
        'monday': data['monday'],
        'tuesday': data['tuesday'],
        'wednesday': data['wednesday'],
        'thursday': data['thursday'],
        'friday': data['friday'],
        'saturday': data['saturday'],
        'sunday': data['sunday']
      },
    );

    debugPrint(res
        ? '${now.add(Duration(days: 1))} ve $id li alarm oluşturuldu.'
        : 'Oluşturulamadı');

    if (data['${DateFormat("EEEE").format(now).toLowerCase()}']) {
      final audioPlayer = AudioPlayer();
      SendPort send = IsolateNameServer.lookupPortByName("$ringPort-$id")!;

      send.send('ring');

      try {
        final assetAudioPath = data['assetAudioPath'] as String;

        if (assetAudioPath.startsWith('http')) {
          await audioPlayer.setUrl(assetAudioPath);
        } else {
          await audioPlayer.setAsset(assetAudioPath);
        }

        final loopAudio = data['loopAudio'];
        if (loopAudio) audioPlayer.setLoopMode(LoopMode.all);

        send.send('Alarm fadeDuration: ${data.toString()}');

        final fadeDuration = (data['fadeDuration'] as int).toDouble();

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

  static Future<bool> stop(int id) async {
    bool res;
    try {
      final SendPort send = IsolateNameServer.lookupPortByName(stopPort)!;
      send.send('stop');
      res = true;
    } catch (e) {
      debugPrint('[Alarm] (main) SendPort error: $e');
      res = false;
    }

    if (!hasAnotherAlarm) stopNotificationOnKillService();
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

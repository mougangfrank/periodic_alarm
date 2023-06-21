import 'package:flutter/material.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'dart:async';

import 'package:periodic_alarm/periodic_alarm.dart';
import 'package:periodic_alarm/services/alarm_notification.dart';
import 'package:periodic_alarm/services/alarm_storage.dart';
import 'package:periodic_alarm_example/view/alarm_screen.dart';
import 'package:periodic_alarm/src/android_alarm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/alarmscreen': (context) => AlarmScreen()
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _subscription;
  StreamSubscription? _subscription2;
  bool alarm = false;
  bool alarm1 = false;
  int? id;

  @override
  void initState() {
    super.initState();
    // onRingingControl();
    PeriodicAlarm.init();
    configureSelectNotificationSubject();
  }

  @override
  void dispose() {
    AndroidAlarm.audioPlayer.dispose();
    super.dispose();
  }

  configureSelectNotificationSubject() {
    _subscription2 ??= AlarmNotification.selectNotificationStream.stream
        .listen((String? payload) async {
      List<String> payloads = [];
      AlarmModel? alarmModel;
      payloads.add(payload!);
      payloads.forEach((element) {
        if (int.tryParse(element) != null) {
          id = int.tryParse(element);
          alarmModel = PeriodicAlarm.getAlarmWithId(id!);
          setState(() {});
        } else if (element == 'stop') {
          PeriodicAlarm.stop(id!);
        } else if (element == "") {
          openAlarmScreen();
        }
      });
    });
  }

  Future<void> setAlarm(int id, DateTime dt) async {
    AlarmModel alarmModel = AlarmModel(
        id: id,
        dateTime: dt,
        assetAudioPath: 'assets/0.mp3',
        notificationTitle: 'Alarm is calling',
        notificationBody: 'Tap to turn off the alarm',
        // monday: true,
        // tuesday: true,
        // wednesday: true,
        // thursday: true,
        // friday: true,
        active: true,
        musicTime: 1,
        incMusicTime: 0.15,
        musicVolume: 0.4,
        incMusicVolume: 0.23);

    if (alarmModel.days.contains(true)) {
      PeriodicAlarm.setPeriodicAlarm(alarmModel: alarmModel);
    } else {
      PeriodicAlarm.setOneAlarm(alarmModel: alarmModel);
    }
  }

  openAlarmScreen() async {
    Future.delayed(Duration(seconds: 1), () async {
      var alarms = await AlarmStorage.getAlarmRinging();
      if (alarms.isNotEmpty) {
        Navigator.pushNamed(context, '/alarmscreen');
      }
    });
  }

  onRingingControl() {
    _subscription = PeriodicAlarm.ringStream.stream.listen(
      (alarmModel) async {
        openAlarmScreen();
        // if (alarmModel.days.contains(true)) {
        //   alarmModel.setDateTime = alarmModel.dateTime.add(Duration(days: 1));
        //   PeriodicAlarm.setPeriodicAlarm(alarmModel: alarmModel);
        // }
      },
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Switch(
          value: alarm,
          onChanged: (value) {
            alarm = value;
            setState(() {});
            if (value) {
              setAlarm(0, DateTime.parse('2023-06-21 16:12:00.000'));
              // setAlarm(1, DateTime(2023, 4, 7, 21, 01, 00));
              // setAlarm(1, DateTime(2023, 4, 7, 19, 54 ,00));
              // setAlarm(1, 20);
            }
          },
        ),
      ),
    );
  }
}

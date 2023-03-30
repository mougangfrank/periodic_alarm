import 'package:flutter/material.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'dart:async';

import 'package:periodic_alarm/periodic_alarm.dart';
import 'package:periodic_alarm/services/alarm_notification.dart';
import 'package:periodic_alarm_example/view/alarm_screen.dart';

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
  int? id;

  @override
  void initState() {
    super.initState();
    onRingingControl();
    PeriodicAlarm.init();
    configureSelectNotificationSubject();
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
        }
      });
    });
  }

  Future<void> setAlarm(int id, int time) async {
    AlarmModel alarmModel = AlarmModel(
      id: id,
      dateTime: DateTime.now().add(Duration(seconds: time)),
      assetAudioPath: 'assets/0.mp3',
      notificationTitle: 'Alarm is calling',
      notificationBody: 'Tap to turn off the alarm',
      active: true,
    );
    PeriodicAlarm.setOneAlarm(alarmModel: alarmModel);
  }

  openAlarmScreen(AlarmModel alarmModel) {
    Navigator.pushNamed(context, '/alarmscreen', arguments: alarmModel);
  }

  onRingingControl() {
    _subscription = PeriodicAlarm.ringStream.stream.listen(
      (alarmModel) async {
        openAlarmScreen(alarmModel);
        if (alarmModel.days.contains(true)) {
          alarmModel.setDateTime = alarmModel.dateTime.add(Duration(days: 1));
          PeriodicAlarm.setPeriodicAlarm(alarmModel: alarmModel);
        }
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
              setAlarm(0, 10);
              // setAlarm(1, 20);
            }
          },
        ),
      ),
    );
  }
}

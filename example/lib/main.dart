import 'package:flutter/material.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'dart:async';

import 'package:periodic_alarm/periodic_alarm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool alarm = false;
  @override
  void initState() {
    super.initState();
    PeriodicAlarm.init();
  }

  Future<void> setAlarm() async {
    AlarmModel alarmModel = AlarmModel(
        id: 0,
        dateTime: DateTime.now(),
        assetAudioPath: 'assets/0.mp3',
        notificationTitle: 'Alarm is calling',
        notificationBody: 'Tap to turn off the alarm',
        tuesday: true,
        active: true);

    PeriodicAlarm.setPeriodicAlarm(alarmModel: alarmModel);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                // setAlarm();
                var model = PeriodicAlarm.getAlarmWithId(1);
              }
            },
          ),
        ),
      ),
    );
  }
}

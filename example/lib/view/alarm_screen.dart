import 'dart:async';

import 'package:flutter/material.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'package:periodic_alarm/periodic_alarm.dart';
import 'package:periodic_alarm/services/alarm_storage.dart';

class AlarmScreen extends StatefulWidget {
  AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  StreamSubscription? _subscription2;
  AlarmModel? alarmModel;

  @override
  void initState() {
    super.initState();
    getAlarm();
  }

  @override
  void dispose() {
    super.dispose();
  }

  getAlarm() async {
    List<String> alarms = await AlarmStorage.getAlarmRinging();
    AlarmModel? alarm = AlarmStorage.getAlarm(int.parse(alarms.last));

    alarmModel = alarm;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // final alarmModel = ModalRoute.of(context)!.settings.arguments as AlarmModel;
    return Scaffold(
      body: Container(
        child: Center(
          child: Row(
            children: [
              ElevatedButton(
                  onPressed: () {
                    PeriodicAlarm.stop(alarmModel!.id);
                    Navigator.of(context).popUntil(ModalRoute.withName('/'));
                  },
                  child: Text('OFF')),
              ElevatedButton(
                  onPressed: () {
                    PeriodicAlarm.stop(alarmModel!.id);
                    alarmModel!.setId = (alarmModel!.id % 8) + 8;
                    PeriodicAlarm.cancelAlarm(alarmModel!.id);
                    alarmModel!.setDateTime = DateTime.now()
                        .add(Duration(seconds: 15));
                    alarmModel!.setActive = true;
                    PeriodicAlarm.setOneAlarm(alarmModel: alarmModel!);
                    Navigator.of(context).popUntil(ModalRoute.withName('/root'));
                  },
                  child: Text('Snooze'))
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'package:periodic_alarm/periodic_alarm.dart';

class AlarmScreen extends StatefulWidget {
  AlarmModel alarmModel;
  AlarmScreen({super.key, required this.alarmModel});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          ElevatedButton(
              onPressed: () {
                PeriodicAlarm.stop(widget.alarmModel.id);
              },
              child: Text('OFF')),
          ElevatedButton(
              onPressed: () {
                PeriodicAlarm.stop(widget.alarmModel.id);
                PeriodicAlarm.cancelAlarm(widget.alarmModel.id);
                widget.alarmModel.setDateTime =
                    widget.alarmModel.dateTime.add(Duration(minutes: 8));
                PeriodicAlarm.setOneAlarm(alarmModel: widget.alarmModel);
              },
              child: Text('Snooze'))
        ],
      ),
    );
  }
}

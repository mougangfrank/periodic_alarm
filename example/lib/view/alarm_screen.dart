import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:periodic_alarm/model/alarms_model.dart';
import 'package:periodic_alarm/periodic_alarm.dart';

class AlarmScreen extends StatefulWidget {
  AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  StreamSubscription? _subscription2;

  @override
  void initState() {
    super.initState();
    // onStopControl();
  }

  @override
  void dispose() {
    // _subscription2!.cancel();
    super.dispose();
  }

  // onStopControl() {
  //   _subscription2 = PeriodicAlarm.stopStream.stream.listen(
  //     (alarmModel) async {
  //       debugPrint('stopped');
  //       Navigator.pop(context);
  //     },
  //   );

  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    final alarmModel = ModalRoute.of(context)!.settings.arguments as AlarmModel;
    return Scaffold(
      body: Container(
        child: Center(
          child: Row(
            children: [
              ElevatedButton(
                  onPressed: () {
                    PeriodicAlarm.stop(alarmModel.id);
                    Navigator.pop(context);
                  },
                  child: Text('OFF')),
              ElevatedButton(
                  onPressed: () {
                    PeriodicAlarm.stop(alarmModel.id);
                    PeriodicAlarm.cancelAlarm(alarmModel.id);
                    alarmModel.setDateTime =
                        alarmModel.dateTime.add(Duration(minutes: 8));
                    PeriodicAlarm.setOneAlarm(alarmModel: alarmModel);
                    Navigator.pop(context);
                  },
                  child: Text('Snooze'))
            ],
          ),
        ),
      ),
    );
  }
}

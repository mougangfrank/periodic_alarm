import 'package:json_annotation/json_annotation.dart';

part 'alarms_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AlarmModel {
  int id;
  final DateTime dateTime;
  final String assetAudioPath;
  final bool loopAudio;
  final double fadeDuration;
  final String? notificationTitle;
  final String? notificationBody;
  final bool enableNotificationOnKill;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  bool active;

  AlarmModel({
    required this.id,
    required this.dateTime,
    required this.assetAudioPath,
    this.loopAudio = true,
    this.fadeDuration = 0.0,
    this.notificationTitle,
    this.notificationBody,
    this.enableNotificationOnKill = true,
    this.monday = false,
    this.tuesday = false,
    this.wednesday = false,
    this.thursday = false,
    this.friday = false,
    this.saturday = false,
    this.sunday = false,
    this.active = false,
  });

  Map<String, dynamic> toJson() => _$AlarmModelToJson(this);

  factory AlarmModel.fromJson(Map<String, dynamic> source) =>
      _$AlarmModelFromJson(source);

  set setId(int id) => this.id = id;

  set setActive(bool active) => this.active = active;
}
